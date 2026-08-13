# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento em [SemVer](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Adicionado

- Aba **Som**: aviso ao concluir uma missão, com escolha do som e do canal de
  áudio. Os sons vêm do próprio jogo e do acervo compartilhado.
- Barra de progresso para objetivos que reportam porcentagem, com textura
  configurável.
- Página **Fundo e borda**: textura, cor, espessura, opacidade e recuo, ou a cor
  da classe na borda.
- Página **Perfis** nas opções, no lugar do submenu do botão de filtro.
- Página **Botões**: cada botão do cabeçalho e o do minimapa desligam
  separadamente.
- Contorno e sombra da fonte; opção de cortar textos longos com reticências em
  vez de quebrar linha.
- Integração com CI e empacotamento pelo BigWigs packager.
- Localização: `Locales/` com `enUS.lua` como padrão e `ptBR.lua` por cima. Uma
  chave sem tradução cai no inglês em vez de sumir.

### Alterado

- Estrutura de pastas: `Adapters/` deu lugar a `Game/`, `Modules/`, `UI/`,
  `Options/` e `System/`, e o `Core/` foi agrupado por assunto.
- Bibliotecas passam a ser baixadas pelo empacotador em vez de commitadas.
- Missões mundiais são listadas por zona, com o ícone de tipo dentro do pino.
- Missão concluída mostra onde entregar em vez do contador cheio, e desce para o
  fim da seção.
- Objetivo bônus recebeu a estrela que o jogo desenha dentro do marcador.

### Corrigido

- Missões mundiais não apareciam quando nenhuma tinha sido rastreada à mão.
- Clicar no pino de uma entrada já selecionada não soltava a seleção.
- Progresso de missões-tarefa não atualizava até a próxima varredura do diário.

## [0.1.0]

Primeira versão do rastreador próprio, com seções de Missões, Campanha, Missões
Mundiais, Objetivos Bônus, Conquistas, Profissões, Atividades Mensais,
Colecionáveis, Tarefas de Iniciativa, Cenário e Eventos do mundo.
