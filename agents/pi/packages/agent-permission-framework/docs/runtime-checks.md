# Runtime Smoke Checks

These checks are primarily scriptable through `pi -p`. They exercise the live Pi extension, SDK-created subagent sessions, background run state, result retrieval, steering, and queue promotion.

`pi -p` runs without the interactive TUI, so it cannot verify `ctrl-o` expansion directly. Use the optional TUI check at the end only for collapsed/expanded rendering.

## Prerequisites

1. Run from this repository root.
2. Restart Pi or run `/reload` before TUI checks after changing this package.
3. Ensure `agents/pi/settings.json` loads `./packages/agent-permission-framework`.
4. Use a model/API configuration that can run short Pi prompts.

## Scripted check 1: foreground subagent

```bash
pi --agent build -p '
Use the subagent tool exactly once with:
- subagent_type: scout
- description: Runtime foreground
- prompt: Return exactly FOREGROUND_OK. Do not call tools.
- run_in_background: false
- max_turns: 2

After the tool returns, answer with only PASS foreground if the result contains FOREGROUND_OK; otherwise answer FAIL foreground and explain briefly.
'
```

Expected: final output contains `PASS foreground`.

## Scripted check 2: background subagent and result retrieval

```bash
pi --agent build -p '
Start one background subagent with:
- subagent_type: scout
- description: Runtime background
- prompt: Return exactly BACKGROUND_OK after one short sentence.
- run_in_background: true
- max_turns: 2

Capture the returned Agent ID. Then call get_subagent_result with wait: true and verbose: false for that ID.
Answer with only PASS background if the retrieved result contains BACKGROUND_OK and no raw JSON record; otherwise answer FAIL background and explain briefly.
'
```

Expected: final output contains `PASS background`.

## Scripted check 3: verbose result retrieval stays textual

```bash
pi --agent build -p '
Start one background subagent with:
- subagent_type: scout
- description: Runtime verbose
- prompt: Return exactly VERBOSE_OK.
- run_in_background: true
- max_turns: 2

Capture the returned Agent ID. Then call get_subagent_result with wait: true and verbose: true for that ID.
Answer with only PASS verbose if the retrieved result contains VERBOSE_OK and the verbose section is headed --- Agent Details --- rather than a raw JSON object dump; otherwise answer FAIL verbose and explain briefly.
'
```

Expected: final output contains `PASS verbose`.

## Scripted check 4: steering a running background subagent

```bash
pi --agent build -p '
Start one background subagent with:
- subagent_type: docs-digger
- description: Runtime steering
- prompt: Do a tiny local docs lookup. If you receive steering, stop and return STEERED_OK plus a short steering summary.
- run_in_background: true
- max_turns: 8

Immediately call steer_subagent for the returned Agent ID with message: Stop now and return STEERED_OK.
Then call get_subagent_result with wait: true and verbose: false for the same ID.
Answer with PASS steering if the result contains STEERED_OK. If the agent completed before steering was delivered but all tools returned cleanly, answer PASS steering-race. Otherwise answer FAIL steering and explain briefly.
'
```

Expected: final output contains `PASS steering` or the documented race result `PASS steering-race`.

## Scripted check 5: queued execution

```bash
pi --agent build -p '
Launch five background subagents as independently as possible, all with run_in_background: true and max_turns: 4:
1. subagent_type: docs-digger, description: Queue smoke 1, prompt: Wait briefly, then return QUEUE_1.
2. subagent_type: docs-digger, description: Queue smoke 2, prompt: Wait briefly, then return QUEUE_2.
3. subagent_type: docs-digger, description: Queue smoke 3, prompt: Wait briefly, then return QUEUE_3.
4. subagent_type: docs-digger, description: Queue smoke 4, prompt: Wait briefly, then return QUEUE_4.
5. subagent_type: docs-digger, description: Queue smoke 5, prompt: Wait briefly, then return QUEUE_5.

Record all Agent IDs. Then call get_subagent_result with wait: true for each ID.
Answer with only PASS queue if all five final results contain their QUEUE_N marker and at least one launch or progress report showed queued state; if all markers appear but no queued state was observable, answer PASS queue-no-observed-queue. Otherwise answer FAIL queue and explain briefly.
'
```

Expected: final output contains `PASS queue` or `PASS queue-no-observed-queue` when the model/provider completed too quickly to observe queueing.

## Scripted check 6: reviewer-style parallel background launch

```bash
pi --agent build -p '
Launch exactly three background subagents in one tool-call batch if possible, each with run_in_background: true and max_turns: 3:
1. subagent_type: scout, description: Reviewer GPT smoke, prompt: Return exactly REVIEWER_GPT_OK. Do not call tools.
2. subagent_type: scout, description: Reviewer GLM smoke, prompt: Return exactly REVIEWER_GLM_OK. Do not call tools.
3. subagent_type: scout, description: Reviewer Kimi smoke, prompt: Return exactly REVIEWER_KIMI_OK. Do not call tools.

Record all three Agent IDs from the launch results, including any queued launch. Then call get_subagent_result with wait: true for each ID.
Answer with only PASS reviewer-parallel if all three IDs were returned independently and their retrieved results contain REVIEWER_GPT_OK, REVIEWER_GLM_OK, and REVIEWER_KIMI_OK respectively. Otherwise answer FAIL reviewer-parallel and explain briefly.
'
```

Expected: final output contains `PASS reviewer-parallel`.

## Scripted check 7: inherited-extension read-only scout can inspect the repository

```bash
pi --agent build -p '
Use the subagent tool once with:
- subagent_type: scout
- description: Runtime inherited extensions
- prompt: {"q":"Find how Pi is integrated into Neovim in this repository","mode":"search","focus":"pi nvim agents home-manager"}
- run_in_background: true
- max_turns: 30

Capture the returned Agent ID. Then call get_subagent_result with wait: true and verbose: false for that ID.
Answer with only PASS inherited-extensions if the result includes at least one concrete repository path reference and does not say read/grep/find/ls were resolved to deny; otherwise answer FAIL inherited-extensions and explain briefly.
'
```

Expected: final output contains `PASS inherited-extensions`.

## Optional TUI rendering check

Run the foreground/background/result/steering scenarios from an interactive Pi TUI session and verify:

- `subagent`, `get_subagent_result`, and `steer_subagent` render compact collapsed rows;
- raw JSON records are not displayed in collapsed mode;
- `ctrl-o` expands `subagent` and `get_subagent_result` when detailed output is needed;
- `steer_subagent` stays concise and matches the upstream `pi-subagents` style.

## Completion criteria

The runtime check passes when scripted checks 1-7 complete with PASS results and the optional TUI check confirms compact rendering after `/reload` or restart.
