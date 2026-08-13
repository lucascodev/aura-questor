# Documentação

Como o Aura Tracker Questor é construído por dentro, para quem vai mexer nele.

| Documento | Para quando você quer |
|---|---|
| [Arquitetura](arquitetura.md) | entender as camadas e por que elas existem |
| [Fluxo de execução](fluxo.md) | saber o que acontece entre um evento do jogo e um pixel na tela |
| [Adicionar conteúdo](adicionar-conteudo.md) | fazer o rastreador mostrar um tipo novo de coisa |
| [Restrições do WoW](restricoes.md) | não repetir os erros que já custaram caro aqui |
| [Desenvolvimento](desenvolvimento.md) | rodar, testar, empacotar e publicar |

## Em uma frase

O addon lê as **APIs públicas de dados** do jogo, monta uma lista em Lua puro e
desenha o próprio frame. Ele não decora nem herda nada do rastreador da
Blizzard.

## O projeto em números

| | |
|---|---|
| Arquivos Lua carregados pelo jogo | 92, sendo 85 nossos e 7 de bibliotecas |
| Linhas no `Core/`, sem uma única API do jogo | ~1.400 |
| Providers de conteúdo, alimentando 11 seções | 10 |
| Eventos do jogo escutados | 26 |
| Preferências | 32 |
| Contratos em `Ports/` | 15 |
| Testes do `Core/`, rodando fora do cliente | 36 |
