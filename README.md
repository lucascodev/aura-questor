# Aura Tracker Questor

Um rastreador de objetivos autônomo para World of Warcraft, escrito sobre as
APIs públicas do jogo. Em inglês e português.

Ele não decora o rastreador da Blizzard: desenha o próprio, lendo os mesmos
dados que o jogo expõe. É a diferença que faz um addon sobreviver a um patch,
a superfície de dados muda muito menos que a de interface.

## O que ele mostra

Missões, Campanha, Missões Mundiais, Objetivos Bônus, Conquistas, Profissões,
Atividades Mensais, Colecionáveis, Tarefas de Iniciativa e Cenário, incluindo
nível da pedra-chave, afixos e mortes em Mítica+.

E uma seção que o rastreador da Blizzard não tem: **Eventos do mundo**, com zona
e tempo restante.

## Recursos

- Filtros por zona, campanha, diárias, masmorra, concluídas e por agrupamento do
  diário
- Ordenação por nível, agrupamento ou título
- Seções recolhíveis, com o estado guardado entre sessões
- Perfis de configuração, um ativo por personagem
- Rolagem, arrastar livremente, largura e altura ajustáveis
- Fonte, tamanho, contorno e sombra escolhidos entre as fontes que os seus addons
  registram
- Fundo e borda com textura do acervo compartilhado, cor, espessura, opacidade e
  recuo, ou a cor da sua classe na borda
- Cada botão do cabeçalho e o do minimapa podem ser desligados um a um
- Tooltip com a descrição da missão e as recompensas, com ícones
- Botão de minimapa e atalhos de teclado

## Instalação

Extraia a pasta `AuraTrackerQuestor` em
`World of Warcraft\_retail_\Interface\AddOns\`.

Dentro do jogo, `/atq` abre as opções e `/atq ajuda` lista os comandos.

## Desenvolvimento

O código segue Clean Architecture, com a regra de dependência apontando para
dentro:

| Pasta | Responsabilidade |
|---|---|
| `Locales/` | textos, `enUS.lua` como padrão e as traduções por cima |
| `Core/` | regras em Lua puro, agrupadas por assunto: `Preferences/`, `Filtering/`, `Tracker/`, `Commands/`. **Nenhuma API do WoW** |
| `Ports/` | contratos de tipo, lidos pelo language server e fora do pacote |
| `Game/` | lê a API do jogo e não desenha nada: `Objectives/`, `Quest/`, `Achievement/` |
| `Modules/` | uma pasta por tipo de conteúdo: o que ela coleta e o que suas entradas fazem |
| `UI/` | frames: `Entry/` desenha uma entrada, `Tracker/` o painel, `Header/` os botões do topo |
| `Options/` | páginas de opções |
| `System/` | chat, comandos, eventos, som e acervo compartilhado |
| `Bootstrap.lua` | composition root, o único lugar que conhece as implementações |

Como o `Core/` não importa nada do jogo, ele roda em Lua puro e pode ser testado
sem abrir o cliente.

Adicionar um tipo de conteúdo novo é criar uma pasta em `Modules/` com o seu
`SectionProvider` e registrá-la no `Bootstrap.lua`. Nada mais muda.

### Testes

```sh
lua Tests/Run.lua
```

Cobrem o `Core/`, que é Lua puro. O harness carrega os arquivos na mesma ordem
do `.toc` e não depende de nada instalado, então roda em qualquer binário Lua e
no CI. Sai com código 1 se algum teste falhar.

### Bibliotecas

`Libs/` não está no repositório: o empacotador busca cada biblioteca da origem
declarada em `.pkgmeta` na hora do release. Clonar e apontar direto para
`Interface\AddOns` não funciona sem elas. Para trabalhar localmente, baixe as
sete de `.pkgmeta` para `Libs/` uma vez, ou instale o
[BigWigs packager](https://github.com/BigWigsMods/packager) e rode-o com `-d`.

### Empacotar

```powershell
.\build.ps1
```

Gera `dist\AuraTrackerQuestor-<versão>.zip`, pronto para instalar. O script
confere que todo arquivo listado no `.toc` está no pacote, um arquivo faltando
só falharia no cliente do jogador, sem pista da causa.

## Licença

MIT. As bibliotecas em `Libs/` pertencem a seus autores e mantêm as licenças
próprias.
