# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento em [SemVer](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Adicionado

- Integração com o TomTom, na aba **Integração** das opções: a seta segue a
  missão supervisionada, criada ao clicar no pin ou ao selecionar pelo mapa, e
  o menu de contexto ganha **Enviar ao TomTom**. A linha mostra a versão do
  addon quando presente; instalado mas desativado aparece em cor secundária, e
  a integração nasce desligada, para o jogador ligar.
- Botão **I** no cabeçalho do rastreador, com tooltip, abrindo direto a página
  de Integração. Desligável na página Botões, como os demais.
- Traduções para **espanhol** (esES e esMX) e **francês** (frFR), com testes de
  paridade cobrindo as quatro línguas.

### Alterado

- A tela principal das opções apresenta o addon: os interruptores gerais e as
  informações de versão, autor e comandos num lugar só. A subpágina
  Informações saiu da lista.
- Título de missão concluída no verde de "pronto para entregar" do jogo, em
  vez do tom pastel.

### Corrigido

- O cabeçalho "Escolha uma:" das recompensas de escolha estava fixo em
  português e aparecia assim em qualquer idioma.

## [0.75.0] - 2026-08-13

### Adicionado

- Estágio de cenário em destaque: um card com a arte que o próprio cenário
  declara e, quando o passo publica widgets, o bloco da própria Blizzard,
  com cronômetro de onda ou o cabeçalho de Imersão com nível, vidas e
  modificadores, tudo se atualizando sozinho.
- Botão de item também em missões mundiais e objetivos bônus, à direita do
  bloco, com moldura, contador de cargas, relógio de recarga e o ícone em
  vermelho fora de alcance.
- Opção **Concluídas no topo**, no menu de filtro e nas opções, para agrupar
  as entradas concluídas no topo da seção em vez do fim.

### Alterado

- A seção diz **Masmorra** em qualquer masmorra, não só em Mítica+, e diz
  **Imersões** dentro de uma Delve.
- Missão com objetivo em porcentagem mostra a linha e a barra, em vez de uma
  barra sem texto.
- Quebrar textos longos passou a ser o padrão em contas novas; perfis
  existentes mantêm a escolha feita.

### Corrigido

- Erro de ancoragem quando uma missão com item entrava na lista: a área de
  rolagem estava presa a uma textura, e frame protegido não aceita isso.
- O clique no botão de item não disparava: o registro de cliques não casava
  com o `ActionButtonUseKeyDown`.
- Em combate, o rastreador com botão de item não tenta mais mexer em frames
  protegidos: escala, tamanho, rolagem, modo de edição e visibilidade
  esperam o combate acabar, e o refresh que segue o fim do combate aplica
  tudo de uma vez.
- O rastreador da Blizzard só é tocado quando o estado pedido muda, em vez
  de a cada atualização.

## [0.74.0] - 2026-08-13

### Adicionado

- Logo próprio, usado na lista de addons do jogo, no botão do minimapa e no
  cabeçalho do rastreador.
- Publicação no Wago Addons junto com o CurseForge, pelo mesmo empacotador.
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

- Cabeçalho do rastreador: o logo vem antes do nome, e uma régua o separa da
  lista, no mesmo desenho que divide as seções.
- Estrutura de pastas: `Adapters/` deu lugar a `Game/`, `Modules/`, `UI/`,
  `Options/` e `System/`, e o `Core/` foi agrupado por assunto.
- Bibliotecas passam a ser baixadas pelo empacotador em vez de commitadas.
- Missões mundiais são listadas por zona, com o ícone de tipo dentro do pino.
- Missão concluída mostra onde entregar em vez do contador cheio, e desce para o
  fim da seção.
- Objetivo bônus recebeu a estrela que o jogo desenha dentro do marcador.

### Corrigido

- O nome do perfil padrão era traduzido, e trocar o idioma do cliente fazia o
  perfil sumir junto com todas as configurações. Passou a ser um identificador
  fixo, e um perfil salvo com o nome antigo é renomeado na carga.

- Missões mundiais não apareciam quando nenhuma tinha sido rastreada à mão.
- Clicar no pino de uma entrada já selecionada não soltava a seleção.
- Progresso de missões-tarefa não atualizava até a próxima varredura do diário.

## [0.1.0]

Primeira versão do rastreador próprio, com seções de Missões, Campanha, Missões
Mundiais, Objetivos Bônus, Conquistas, Profissões, Atividades Mensais,
Colecionáveis, Tarefas de Iniciativa, Cenário e Eventos do mundo.
