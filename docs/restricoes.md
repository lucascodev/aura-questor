# Restrições do WoW

Limitações da API que já causaram problemas neste projeto ou em addons
conhecidos. Recomendada a leitura antes de alterar qualquer frame.

## Taint e valores secretos

O jogo separa execução **limpa** (código da Blizzard) de **contaminada** (código
de addon). Quando um addon toca um frame protegido, a contaminação se propaga, e
a ação é bloqueada.

Desde o 12.0 isso ficou mais rígido com os *secret values*: certas leituras
retornam valores que só podem ser usados em execução limpa, e usá-los fora dela
gera o erro `Secret values are only allowed during untainted execution`.

### Esconder o rastreador da Blizzard

Há apenas uma forma segura:

```lua
frame:SetAlpha(0)
frame:EnableMouse(false)
```

**Nunca** `Hide()`, `SetScale()` ou `SetPoint()` nele. Esse foi o erro que
quebrou outro addon de rastreador no 12.1, e `Hide()` num frame com filho
protegido é bloqueado em combate. Ver
[`Game/BlizzardTracker.lua`](../Source/Game/BlizzardTracker.lua).

## Frames protegidos e combate

`SecureActionButtonTemplate` torna protegido **todo frame acima dele**. Um botão
de item de missão dentro de um bloco protege o bloco, o conteúdo e o painel.

Consequências observadas neste projeto:

- criar os botões antecipadamente gerou **116 erros `ADDON BLOCKED`** de uma vez
- em combate não é possível mover, redimensionar nem esconder o que está acima
  deles

Solução adotada: o botão é criado sob demanda, apenas quando uma missão de fato
tem item. Enquanto nenhum existir, nada está protegido e o rastreador atualiza
normalmente em combate. Quando existe,
[`OwnTrackerFrame:IsLockedByCombat`](../Source/UI/Tracker/OwnTrackerFrame.lua) segura o
redesenho até `PLAYER_REGEN_ENABLED`.

Atributos de botão seguro também não podem ser alterados em combate. É a mesma
limitação do rastreador da Blizzard.

O que **não** é protegido: o texto de um FontString e o valor de uma StatusBar.
Por isso, em combate, `EntryBlockPool:RewriteInPlace` reescreve as linhas e as
barras dos blocos que já estão na tela, sem mover, criar, mostrar ou esconder
frame nenhum. Uma missão mundial de "matar criaturas" só progride dentro do
combate; sem isso a barra ficava parada até a luta acabar. Bloco cuja forma
mudaria (linha a mais, entrada nova, texto que passa a quebrar) espera o
refresh que segue o `PLAYER_REGEN_ENABLED`.

## Taint no mapa: um erro conhecido e sem correção

Abrir os detalhes de uma missão a partir de um addon, via
`QuestMapFrame_OpenToQuestDetails`, executa toda a máquina do mapa em contexto
inseguro, e cada variável que ela escreve nessa passada fica manchada. Quando o
próprio jogo repassa por essas variáveis mais tarde, dentro de combate, as
chamadas protegidas dos pins (`SetPassThroughButtons`,
`SetPropagateMouseClicks`) são bloqueadas, e o `ADDON_ACTION_BLOCKED` culpa
quem manchou primeiro: este addon.

A assinatura no BugSack é uma pilha que nasce num clique (no nosso painel ou no
rastreador da Blizzard, quando os dois estão ligados), atravessa
`QuestMapFrame_OpenToQuestDetails` e morre em `CheckMouseButtonPassthrough` nos
providers do mapa.

Não existe forma sem taint de um addon abrir os detalhes de missão; todo
rastreador de terceiros carrega esse mesmo erro. O efeito real é só a flag de
clique-atravessa dos pins ficar desatualizada até o fim do combate; nenhuma
funcionalidade se perde.

O que dá para fazer é encolher a janela: o modo de exibição do mapa só é
escrito quando muda de verdade (`MapNavigator.Open`), porque reescrever o valor
que já está lá mancharia o campo que o atalho de mapa da Blizzard lê a cada
tecla M. Quando a própria Blizzard reescreve o campo, a mancha some até o
próximo toque nosso.

Na mesma família: escrever a supervisão (`C_SuperTrack`) dentro de combate
dispara na hora o refresh dos pins do mapa em contexto manchado, e o
`SetPassThroughButtons` de cada pin é bloqueado. Por isso `SuperTracking`
adia a escrita para o fim do combate; só o último pedido vale.

Abrir o painel de opções (`Settings.OpenToCategory`) também é protegido em
combate desde o 12.x. `OptionsPanel` avisa no chat e não tenta.

## Nome do addon é identidade

O cliente guarda dados do jogador pelo nome da pasta do addon, e nada disso
sobrevive a um rename por conta própria:

- **SavedVariables** ficam em `WTF\...\SavedVariables\<Pasta>.lua`. Ao virar
  `AuraQuestor`, o jogo passou a ler `AuraQuestor.lua`, vazio; nenhuma API lê
  o arquivo de outro addon. Por isso o zip leva a pasta `AuraTrackerQuestor`
  como ponte: só o manifesto, com `## SavedVariables: AuraTrackerQuestorDB`,
  para o jogo continuar carregando a tabela antiga. `LegacyDatabase.Resolve`
  a adota quando a nova está vazia. Em ordem alfabética `AuraQuestor` carrega
  antes de `AuraTrackerQuestor`, então o `## OptionalDeps: AuraTrackerQuestor`
  do manifesto principal é o que garante a ordem certa. Os dois manifestos
  precisam declarar o mesmo `## Interface` (há teste), senão a ponte fica
  "desatualizada" e some em silêncio para quem não carrega addons antigos.
- **Atalhos de teclado** são gravados pelo nome do comando
  (`AURATRACKERQUESTOR_TOGGLE`, `AURATRACKERQUESTOR_OPTIONS`). Esses nomes
  ficaram congelados de propósito em `Bindings.xml` e `KeyBindings.lua`;
  renomeá-los desatribuiria a tecla de todo mundo.
- **Nome do frame** (`AuraQuestorTracker`) e **objeto LibDataBroker**
  (`AuraQuestor`) mudaram com a pasta; addons de terceiros que ancoravam por
  nome ou guardavam o slot do datatext precisam reapontar.

A ponte pode sair do pacote algumas versões depois, quando não houver mais
quem venha do nome antigo.

## Medir frames

`GetBottom()` e funções semelhantes devolvem coordenadas de tela que podem estar
**desatualizadas**: o jogo só recalcula a posição no fim do frame. Medir altura
de conteúdo com elas resultou numa lista sempre uma missão mais curta e num
scroll que não se movia.

Some as alturas manualmente, ou use `GetStringHeight()` **depois** de definir a
largura do font string. Sem largura definida, um texto com quebra reporta a
altura de uma linha apenas.

## Tooltip e seleção de missão

Ler a descrição ou as recompensas de uma missão exige selecioná-la, e a seleção
é **estado global**, lido também pelo diário. Sem salvar e restaurar o valor
anterior, passar o mouse pelo rastreador alterava silenciosamente o que o diário
exibia:

```lua
local previous = C_QuestLog.GetSelectedQuest()
C_QuestLog.SetSelectedQuest(entry.id)
-- ler
if previous then
	C_QuestLog.SetSelectedQuest(previous)
end
```

## Duas fontes, não uma

Falha que ocorreu três vezes neste projeto: ler apenas parte do que o jogo
publica.

| O que | Precisa de |
|---|---|
| Missões mundiais | `GetTasksTable()`, não só a lista de rastreamento manual |
| Eventos | `GetOngoingEvents()` **e** `GetScheduledEvents()` |
| Recompensas | garantidas **e** as de escolha (`GetNumQuestLogChoices`) |

Quando algo não aparece, verifique primeiro se existe uma segunda fonte não
consultada.

## Painéis sob demanda

O painel de conquistas é *load on demand*. Chamar
`OpenAchievementFrameToAchievement` direto dá erro; a sequência é
`AchievementFrame_LoadUI()` e só então abrir e selecionar. Ver
[`Game/Achievement/Panel.lua`](../Source/Game/Achievement/Panel.lua).

## Assinaturas contraintuitivas

- `GameTooltip:SetText(texto, r, g, b, alpha, wrap)`: o quinto parâmetro é
  **alpha**. No `AddLine` o quinto é o wrap. Passar a flag de quebra logo após a
  cor a coloca no slot de alpha e gera erro.
- `StaticPopup` não tem `.editBox`; use `popup:GetEditBox()`.
- `SOUNDKIT` e FileDataID são **espaços de identificação distintos**. Kit toca
  com `PlaySound`, arquivo com `PlaySoundFile`. Trocar um pelo outro não produz
  som algum.

## Fontes do jogo

A fonte padrão não contém todos os glifos. `→` é renderizado como quadrado
vazio; use `>` ou `·`.

## Como verificar

O arquivo `_retail_/Logs/General.log` acumula tudo que o cliente registra, então
o tamanho dele não diz nada. O que interessa são as linhas `[E][Lua] Lua Error`
com data posterior ao último `/reload`:

```sh
grep -E "^$(date +%-m/%-d) 1[0-9]:" General.log | grep "Lua Error"
```

Cada erro traz a pilha completa com o caminho do arquivo, o que é mais rápido do
que diagnosticar pelo sintoma na tela. O caminho também denuncia log velho: se
ele aponta para um arquivo que não existe mais, o erro é de antes de alguma
reorganização.
