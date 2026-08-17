# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento em [SemVer](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Corrigido

- Missão que se completa à distância mas cuja notificação já tinha passado
  (completada antes do login, ou o aviso descartado) aparecia como entrega
  normal e o clique abria o diário. A leitura passou a seguir a marca do
  próprio diário (`isAutoComplete`), como o rastreador da Blizzard, e a
  entrada mostra "Missão cumprida" e "(clique para concluir)"; o clique abre
  a janela de conclusão.
- Em combate, com botão de item na lista, o rastreador não atualizava nada até
  a luta acabar, e uma missão mundial de "matar criaturas" ficava com a barra
  parada em 0% enquanto o mapa já dizia 30%. Agora o texto das linhas e o
  valor das barras dos blocos na tela são reescritos em lugar durante o
  combate; só o que mudaria de forma (linha a mais, entrada nova) espera o
  fim da luta.

## [0.79.1] - 2026-08-17

### Adicionado

- **Rastrear missões mundiais**, no menu de filtro e na página Conteúdo, o
  mesmo interruptor que os eventos já tinham: desligado, a seção some por
  inteiro, sem depender de estar dentro da área de alguma.

### Corrigido

- Missões mundiais rastreadas pelo mapa não apareciam: a seção lia só as da
  área em que o jogador está. Agora lista as duas fontes, na ordem do
  rastreador da Blizzard: primeiro as da área, depois as rastreadas, onde
  quer que estejam. **Parar de rastrear** numa missão mundial usava a chamada
  do diário e não fazia nada; passou a usar a lista certa e, se a missão era
  a supervisionada, solta a seta junto.

## [0.79.0] - 2026-08-17

### Alterado

- O addon passa a se chamar **Aura Questor: Objective Tracker**; a pasta e o
  manifesto viram `AuraQuestor`. Ninguém perde configuração: o zip leva junto a
  pasta `AuraTrackerQuestor` como ponte, só com o manifesto que mantém a tabela
  antiga carregada, e o addon a adota no primeiro login com o nome novo,
  avisando no chat. Os atalhos de teclado e o `/atq` continuam os mesmos.
  Mudaram com a pasta o nome do frame (`AuraQuestorTracker`) e o objeto do
  LibDataBroker (`AuraQuestor`): addons que ancoravam por nome ou guardavam o
  slot do datatext precisam reapontar. A ponte pode ser removida depois do
  primeiro login e sairá do pacote em versões futuras.

### Corrigido

- Com o painel estreito, os botões do cabeçalho passavam por cima do nome do
  addon. O nome agora termina antes da fila de botões e corta com reticências
  quando não cabe.

## [0.78.0] - 2026-08-16

### Adicionado

- Botão de recolher no canto do cabeçalho, o mesmo do rastreador da Blizzard:
  o painel encolhe até sobrar só o cabeçalho e volta com outro clique. O
  estado fica salvo no perfil, e o cabeçalho não sai do lugar ao recolher.
- **Modo de edição** também no menu de filtro, no grupo Janela ao fim da
  lista, para liberar o arrasto sem abrir as opções.

## [0.77.0] - 2026-08-15

### Alterado

- As opções foram redesenhadas por inteiro, com identidade própria na paleta
  do logo: fundo quase preto, cards de seção e um único destaque azul. Oito
  subpáginas viraram cinco (Aparência, Moldura, Conteúdo, Integração e
  Perfis), sem remover nenhuma preferência: Avançado entrou na página
  principal, Botões e Som entraram em Conteúdo, e Fundo e borda virou Moldura.
  As dicas saíram do tooltip e passaram a texto de apoio na própria linha,
  interruptores substituíram os checkboxes, e a Integração virou uma lista com
  versão e estado por addon. As fontes Inter e JetBrains Mono acompanham o
  addon (licença SIL OFL) e ficam disponíveis no acervo compartilhado.
- A busca nativa das Opções e o botão Padrões deixam de alcançar essas
  páginas, consequência aceita de desenhá-las por conta própria.
- As pastas de código desceram para `Source/`, deixando a raiz do addon só com
  o manifesto, os atalhos, mídia, locales e bibliotecas. Nenhuma mudança de
  comportamento.
- O rastreador adota a tipografia das opções: Inter vira a fonte padrão em
  instalações novas (perfis existentes mantêm a escolha), e as porcentagens
  das barras de progresso passam a JetBrains Mono, que alinha os dígitos.

### Adicionado

- Menu de contexto de missão ganhou **Abandonar missão**, com a confirmação
  da própria Blizzard, apenas quando a missão pode ser abandonada.
- Missão que se completa à distância aparece na lista mesmo sem estar sendo
  observada, com o aviso da Blizzard no lugar dos objetivos, e o clique abre a
  janela de recompensa dali. Vale também para missões oferecidas à distância,
  que mostram "Nova missão descoberta" e abrem a oferta ao clicar.

### Corrigido

- O card de estágio ficava sem a arte da Blizzard quando o cenário não
  declarava um conjunto próprio: a busca parava antes das reservas. Agora o
  card veste a arte no tamanho dela e segue o desenho do jogo, com o número do
  estágio em destaque, o nome menor embaixo e **Estágio Final** no último.
- Supervisionar uma entrada durante o combate manchava o refresh dos pins do
  mapa e gerava avisos de ação bloqueada. A escrita agora espera o combate
  acabar; só o último clique vale.
- Abrir as opções em combate é protegido pelo jogo desde o 12.x e caía em
  ação bloqueada. O clique agora avisa no chat e não tenta.

## [0.76.1] - 2026-08-14

### Corrigido

- O modo de exibição do mapa só é escrito quando muda de verdade. Reescrever o
  valor que já estava lá manchava o campo que o atalho de mapa lê, e abrir o
  mapa em combate gerava avisos de ação bloqueada em nome do addon.

## [0.76.0] - 2026-08-14

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
