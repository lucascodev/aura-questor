# Desenvolvimento

## Preparar

```sh
git clone <repo>
cd aura-tracker-questor
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

Para trabalhar com o jogo aberto, aponte um link simbólico da pasta do projeto
para `World of Warcraft\_retail_\Interface\AddOns\AuraTrackerQuestor`.

## Testar

```sh
lua Tests/Run.lua
```

36 testes sobre o `Core/`, em Lua puro, sem nada para instalar. O harness carrega
`Locales/` e `Core/` na mesma ordem do `.toc` e simula o vararg que o jogo passa
para cada arquivo. Sai com código 1 se algo falhar.

O que está coberto: filtros, ordenação, montagem das seções, detecção de
conclusão, cores, perfis, preferências, categorias de conquista e a consistência
entre os arquivos de locale.

O que **não** dá para cobrir assim: tudo que toca a API do jogo ou desenha frame.
Isso só se verifica no cliente.

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

Gera `dist\AuraTrackerQuestor-<versão>.zip` com uma única pasta raiz, que é como
o jogo encontra um addon. O script confere o `.toc` **nos dois sentidos**:

- arquivo listado que não foi empacotado — falharia no cliente do jogador, sem
  pista da causa
- arquivo empacotado que não está listado — nunca carrega, e parece que o
  recurso não foi escrito

`Ports/` e `Tests/` ficam de fora: o primeiro é só anotação de tipo, o segundo
não é do jogo.

## Publicar

```sh
git tag v0.70.0
git push --tags
```

A tag dispara [`release.yml`](../.github/workflows/release.yml), que roda o
BigWigs packager: busca as bibliotecas, aplica o `.pkgmeta`, monta o zip e
publica no GitHub Releases e no CurseForge.

Antes da primeira tag:

1. criar o projeto no CurseForge
2. guardar `CF_API_KEY` nos secrets do repositório
3. adicionar `## X-Curse-Project-ID` ao `.toc`

Sem isso o workflow falha no upload.

## Convenções

**Commits** em [Conventional Commits](https://www.conventionalcommits.org/), em
português, como o histórico já usa: `feat:`, `fix:`, `refactor:`, `test:`,
`build:`, `chore:`, `style:`.

**Comentários** explicam a decisão, não o que a linha faz. Se um bloco precisa de
comentário para ser entendido, normalmente ele quer virar uma função com nome.
Código em inglês, textos visíveis ao jogador em `Locales/`.

**Indentação** com tab, conforme o [`.editorconfig`](../.editorconfig). Finais de
linha normalizados em LF pelo [`.gitattributes`](../.gitattributes).

**Textos** nunca ficam soltos no código. Chave nova entra em `Locales/enUS.lua`
**e** em `ptBR.lua` — há um teste que falha se uma das duas faltar, ou se a
contagem de `%s` divergir entre elas.

## Versão

A versão vive num lugar só, o `## Version:` do `.toc`. O `build.ps1` lê dali para
nomear o zip, e o `AddonMetadata` lê para mostrar nas opções e no `/atq status`.
