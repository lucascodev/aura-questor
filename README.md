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
| `Source/Core/` | regras em Lua puro: `Preferences/`, `Filtering/`, `Tracker/`, `Commands/`. **Nenhuma API do WoW** |
| `Source/Ports/` | contratos de tipo, lidos pelo language server e fora do pacote |
| `Source/Game/` | lê a API do jogo e não desenha nada: `Objectives/`, `Quest/`, `Achievement/` |
| `Source/Modules/` | uma pasta por tipo de conteúdo: o que ela coleta e o que suas entradas fazem |
| `Source/UI/` | frames: `Entry/` desenha uma entrada, `Tracker/` o painel, `Header/` os botões do topo |
| `Source/Options/` | páginas de opções e o kit `Components/` |
| `Source/System/` | chat, comandos, eventos, som e acervo compartilhado |
| `Source/Bootstrap.lua` | composition root, o único lugar que conhece as implementações |

```sh
lua Tests/Run.lua     # os testes do Core, sem abrir o jogo
luacheck .            # análise estática
.\build.ps1           # gera dist\AuraTrackerQuestor-<versão>.zip
```

`Libs/` não está no repositório: o empacotador busca as bibliotecas na origem
declarada em `.pkgmeta`. Um clone limpo não roda no jogo antes de trazê-las.

A documentação completa está em **[docs/](docs/)**:

| | |
|---|---|
| [Arquitetura](docs/arquitetura.md) | as camadas e a regra de dependência |
| [Fluxo de execução](docs/fluxo.md) | inicialização, ciclo de atualização e combate |
| [Adicionar conteúdo](docs/adicionar-conteudo.md) | implementar um tipo de conteúdo novo |
| [Restrições do WoW](docs/restricoes.md) | taint, combate e limites da API |
| [Desenvolvimento](docs/desenvolvimento.md) | ambiente, testes, empacotamento e publicação |

## Licença

MIT. As bibliotecas em `Libs/` pertencem a seus autores e mantêm as licenças
próprias.
