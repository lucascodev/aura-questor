# Restrições do WoW

O que segue são armadilhas que já custaram tempo neste projeto ou quebraram
addons conhecidos. Vale ler antes de mexer em frame.

## Taint e valores secretos

O jogo separa execução **limpa** (código da Blizzard) de **contaminada** (código
de addon). Quando um addon toca um frame protegido, a contaminação se propaga, e
a ação é bloqueada.

Desde o 12.0 isso ficou mais rígido com os *secret values*: certas leituras
retornam valores que só podem ser usados em execução limpa, e usá-los fora dela
derruba com `Secret values are only allowed during untainted execution`.

### Esconder o rastreador da Blizzard

Só existe um jeito seguro:

```lua
frame:SetAlpha(0)
frame:EnableMouse(false)
```

**Nunca** `Hide()`, `SetScale()` nem `SetPoint()` nele. Foi exatamente esse o
erro que derrubou outro addon de rastreador no 12.1, e `Hide()` num frame com
filho protegido é bloqueado em combate. Ver
[`Game/BlizzardTracker.lua`](../Game/BlizzardTracker.lua).

## Frames protegidos e combate

`SecureActionButtonTemplate` torna protegido **todo frame acima dele**. Um botão
de item de missão dentro de um bloco protege o bloco, o conteúdo e o painel.

Consequências, todas já sentidas aqui:

- criar os botões antecipadamente rendeu **116 erros `ADDON BLOCKED`** de uma vez
- em combate não dá para mover, redimensionar nem esconder o que está acima deles

O que o projeto faz: o botão é criado **preguiçosamente**, só quando uma missão
realmente tem item. Enquanto nenhum existir, nada está protegido e o rastreador
atualiza normalmente em combate. Quando existe,
[`OwnTrackerFrame:IsLockedByCombat`](../UI/Tracker/OwnTrackerFrame.lua) segura o
redesenho até `PLAYER_REGEN_ENABLED`.

Atributo de botão seguro também não pode ser trocado em combate. É a mesma
limitação que o rastreador da Blizzard tem.

## Medir frames

`GetBottom()` e afins devolvem coordenadas de tela que podem estar **velhas**:
o jogo só recalcula a posição no fim do frame. Medir altura de conteúdo com elas
resultou numa lista sempre uma missão mais curta e num scroll que não andava.

Some as alturas você mesmo, ou use `GetStringHeight()` **depois** de dar largura
ao font string. Sem largura definida, um texto com quebra reporta a altura de
uma linha só.

## Tooltip e seleção de missão

Ler a descrição ou as recompensas de uma missão exige selecioná-la, e a seleção
é **estado global** que o diário também lê. Sem salvar e devolver, passar o mouse
pelo rastreador mudava silenciosamente o que o diário mostrava:

```lua
local previous = C_QuestLog.GetSelectedQuest()
C_QuestLog.SetSelectedQuest(entry.id)
-- ler
if previous then
	C_QuestLog.SetSelectedQuest(previous)
end
```

## Duas fontes, não uma

Erro que se repetiu três vezes aqui: ler só metade do que o jogo publica.

| O que | Precisa de |
|---|---|
| Missões mundiais | `GetTasksTable()`, não só a lista de rastreamento manual |
| Eventos | `GetOngoingEvents()` **e** `GetScheduledEvents()` |
| Recompensas | garantidas **e** as de escolha (`GetNumQuestLogChoices`) |

Quando algo "não aparece", desconfie primeiro de uma segunda fonte esquecida.

## Painéis sob demanda

O painel de conquistas é *load on demand*. Chamar
`OpenAchievementFrameToAchievement` direto dá erro; a sequência é
`AchievementFrame_LoadUI()` e só então abrir e selecionar. Ver
[`Game/Achievement/Panel.lua`](../Game/Achievement/Panel.lua).

## Assinaturas que enganam

- `GameTooltip:SetText(texto, r, g, b, alpha, wrap)` — o quinto parâmetro é
  **alpha**. No `AddLine` o quinto é o wrap. Passar a flag de quebra logo após a
  cor cai no slot de alpha e derruba.
- `StaticPopup` não tem `.editBox`; use `popup:GetEditBox()`.
- `SOUNDKIT` e FileDataID são **espaços diferentes**. Kit toca com `PlaySound`,
  arquivo com `PlaySoundFile`. Trocar um pelo outro não toca nada.

## Fontes do jogo

A fonte padrão não tem todos os glifos. `→` renderiza como quadrado vazio. Use
`>` ou `·`.

## Como verificar

O critério que vem funcionando: depois de um `/reload`, o arquivo
`_retail_/Logs/General.log` deve estar com **0 bytes**. Qualquer erro ou taint
aparece ali com a pilha inteira, e é bem mais rápido que caçar o sintoma na tela.
