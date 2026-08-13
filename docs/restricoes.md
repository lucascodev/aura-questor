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
[`Game/BlizzardTracker.lua`](../Game/BlizzardTracker.lua).

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
[`OwnTrackerFrame:IsLockedByCombat`](../UI/Tracker/OwnTrackerFrame.lua) segura o
redesenho até `PLAYER_REGEN_ENABLED`.

Atributos de botão seguro também não podem ser alterados em combate. É a mesma
limitação do rastreador da Blizzard.

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
[`Game/Achievement/Panel.lua`](../Game/Achievement/Panel.lua).

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
