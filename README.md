# Aura Tracker Questor

Um rastreador de objetivos autônomo para World of Warcraft, escrito sobre as
APIs públicas do jogo.

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

| Camada | Responsabilidade |
|---|---|
| `Core/` | domínio puro, filtros, ordenação, perfis. **Nenhuma API do WoW** |
| `Ports/` | contratos de tipo, lidos pelo language server e fora do pacote |
| `Adapters/` | tudo que fala com o jogo: providers, frames, ações |
| `Bootstrap.lua` | composition root, o único lugar que conhece as implementações |

Como o `Core/` não importa nada do jogo, ele roda em Lua puro e pode ser testado
sem abrir o cliente.

Adicionar um tipo de conteúdo novo é escrever um `SectionProvider` e registrá-lo
no `Bootstrap.lua`. Nada mais muda.

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
