# Documentação

Documentação técnica do Aura Tracker Questor, para quem vai modificar o código.

| Documento | Assunto |
|---|---|
| [Arquitetura](arquitetura.md) | as camadas e a regra de dependência |
| [Fluxo de execução](fluxo.md) | inicialização, ciclo de atualização e combate |
| [Adicionar conteúdo](adicionar-conteudo.md) | implementar um tipo de conteúdo novo |
| [Restrições do WoW](restricoes.md) | conhecer os limites da API antes de mexer em frame |
| [Desenvolvimento](desenvolvimento.md) | ambiente, testes, empacotamento e publicação |

## Resumo

O addon lê as **APIs públicas de dados** do jogo, monta a lista de objetivos em
Lua puro e desenha o próprio frame. Não modifica nem depende do rastreador da
Blizzard.

## O projeto em números

| | |
|---|---|
| Arquivos Lua carregados pelo jogo | 106, sendo 99 nossos e 7 de bibliotecas |
| Linhas no `Core/`, sem uma única API do jogo | ~1.600 |
| Providers de conteúdo, alimentando 11 seções | 10 |
| Eventos do jogo escutados | 27 |
| Preferências | 35 |
| Contratos em `Source/Ports/` | 17 |
| Testes rodando fora do cliente | 141 |
