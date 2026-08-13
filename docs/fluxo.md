# Fluxo de execução

## Partida

O addon acorda duas vezes, e a separação é deliberada.

```mermaid
sequenceDiagram
    participant Jogo
    participant Loader as Bootstrap
    participant Build
    participant Start

    Jogo->>Loader: ADDON_LOADED
    Note over Loader: só agora as SavedVariables existem
    Loader->>Build: Build()
    Build->>Build: perfis, preferências, providers,<br/>renderer, opções, botões
    Jogo->>Loader: PLAYER_LOGIN
    Note over Loader: a tela de carregamento acabou;<br/>o chat guarda o que for escrito
    Loader->>Start: Start()
    Start->>Start: prende os botões no cabeçalho
    Start->>Start: primeiro Refresh
```

`Build()` roda em `ADDON_LOADED` porque é o primeiro momento em que
`AuraTrackerQuestorDB` existe. `Start()` espera `PLAYER_LOGIN` porque o quadro de
chat restaura o histórico depois da tela de carregamento e descarta o que foi
escrito antes: a mensagem de boas-vindas sumia.

Se o addon carregar com o jogador já logado (um `/reload`), `PLAYER_LOGIN` não
vem mais. Por isso o loader confere `IsLoggedIn()` e chama `Start()` na hora.

## O ciclo de atualização

É o caminho que roda o tempo todo.

```mermaid
sequenceDiagram
    participant Jogo
    participant Events as TrackerEvents
    participant Boot as RefreshFromGame
    participant Display as TrackerDisplay
    participant Content as TrackerContent
    participant Providers as 10 SectionProviders
    participant Frame as OwnTrackerFrame
    participant Pool as EntryBlockPool

    Jogo->>Events: QUEST_LOG_UPDATE (em rajada)
    Events->>Events: junta 0,15 s
    Events->>Boot: uma única chamada
    Boot->>Display: Refresh()
    Display->>Display: esconde o rastreador da Blizzard
    Display->>Display: aplica visibilidade dos botões
    Display->>Content: Build()
    Content->>Providers: Collect()
    Providers-->>Content: TrackerSection[]
    Content->>Content: descarta seções vazias
    Content->>Content: ordena seções por order
    Content->>Content: ordena entradas, concluídas por último
    Content-->>Display: seções prontas
    Display->>Display: aplica fonte, escala, fundo
    Display->>Frame: Render(seções visíveis)
    Frame->>Pool: Build(entrada) por linha
    Boot->>Boot: CompletionWatcher detecta a virada
    Boot->>Boot: toca o som, se houver
```

### Por que o debounce

`QUEST_LOG_UPDATE` dispara em rajada: várias vezes para uma única entrega de
missão. Sem juntar, o rastreador seria reconstruído meia dúzia de vezes em
frames consecutivos. Os 0,15 s de
[`TrackerEvents`](../System/TrackerEvents.lua) colapsam a rajada numa
reconstrução só. São 26 eventos escutados, todos passando pelo mesmo funil.

### Por que o pool

Reconstruir a lista significa desenhar até algumas dezenas de entradas. Criar
frames a cada atualização vazaria widgets pela sessão inteira, porque o WoW não
destrói frame. O [`EntryBlockPool`](../UI/Entry/BlockPool.lua) reaproveita: não é
otimização, é requisito.

## Mudança de preferência

Existe **um** caminho, e ele foi unificado de propósito: antes havia dois, e só
um deles avisava quem precisava saber.

```mermaid
flowchart TD
    Nativo["Controle nativo<br/><i>Settings API</i>"] -->|escreve direto na tabela| Tabela[(values)]
    Nativo -->|dispara| Notify["Preferences:Notify"]

    Mao["Controle desenhado à mão<br/><i>Fundo e borda, Perfis</i>"] --> Set["Preferences:Set"]
    Externo["Menu do cabeçalho<br/><i>SelectValue</i>"] --> Set
    Externo -->|se houver controle nativo| Nativo

    Set --> Tabela
    Set --> Callback
    Notify --> Callback["onChanged(chave)"]

    Callback --> Refresh["display:Refresh()"]
    Callback --> Som["som de prévia,<br/>se a chave for a do som"]
```

`Preferences:Set` cala quando o valor não mudou, então mexer num controle e
voltar ao valor original não redesenha nada.

## Combate

Um botão de item de missão é um `SecureActionButtonTemplate`, e isso torna
**protegido todo frame acima dele**. Mover, redimensionar ou esconder frame
protegido em combate é bloqueado pelo jogo.

```mermaid
flowchart LR
    Refresh["Render()"] --> Check{"o pool já criou<br/>algum botão de item?"}
    Check -->|não| Draw["desenha normalmente"]
    Check -->|sim| Combat{"em combate?"}
    Combat -->|não| Draw
    Combat -->|sim| Skip["não faz nada"]
    Skip -.-> Regen["PLAYER_REGEN_ENABLED<br/>traz o refresh de volta"]
    Regen --> Draw
```

Nada trava enquanto nenhum botão de item existir, que é o caso comum. E quem
desliga **Botões de item das missões** nas opções nunca cria nenhum, então o
rastreador atualiza durante a luta inteira.
