---
name: skill-test-designer
description: |
  Design test scenarios for skills through user interview. Reads the target
  skill, interviews the user about scope and edge cases, saves scenario files
  for skill-tester to execute.

  Use when: "придумай тесты для скилла", "создай сценарии тестирования",
  "протестируй скилл", "design skill tests", "prepare test scenarios"
---

# Skill Test Designer

Design test scenarios for skills. Interview the user to understand what to
test, then create detailed scenario files for skill-tester to execute.

## Phase 1: Understand the Skill

1. User provides skill name or path
2. Read the target skill's SKILL.md + ALL referenced files completely
3. Map out:
   - Skill type: procedural / informational / dialogue / one-shot
   - Input: what does the skill expect? (user message, task file, structured data)
   - Output: what should the skill produce? (files, messages, actions, decisions)
   - Phases: list all phases/steps with their checkpoints
   - References: list all files the skill tells agents to read
   - Decision points: where does the skill branch based on input?
   - Dialogue points: where does the skill ask the user questions?
4. Present this map to the user: "Here's what I found in the skill: [summary].
   What do you want to focus on?"

**Checkpoint:** Skill map presented to user. User confirmed focus area.

## Phase 2: Interview the User

Discuss with the user to define the test scope:

1. **Scope**: "Do you want to test the whole skill or specific parts?"
   - Whole skill → test full workflow end-to-end
   - Specific parts → focus scenarios on those areas

2. **Scenarios**: Propose 1 happy-path + 2-3 edge cases based on skill analysis.
   For each, explain WHY this scenario tests an important aspect.
   - Happy path: the most common, standard use case
   - Edge cases: where the skill might break or behave unexpectedly
     Examples of edge cases:
     - Ambiguous user input ("ну сделай что-нибудь")
     - Missing context (no project-knowledge files available)
     - Contradictory requirements mid-dialogue
     - Unusually large or unusually small scope
     - Input that triggers rarely-used branches in the skill
   Let the user adjust: add, remove, modify scenarios.

3. **Task prompts**: For each scenario, draft the exact message the runner will
   receive. Show to user. These must be natural — exactly what the user would
   type in a real session.
   - For coding skills: may need a task file (create it, show to user)
   - For dialogue skills: just the opening message
   - For one-shot skills: the full request

4. **Acceptance criteria**: For each scenario, propose specific checks.
   The number depends on skill complexity — simple skills may have 5,
   complex procedural skills can have 15+. Show to user. Categories:
   - **[Process]**: Did the agent follow the skill's workflow?
     Examples: "Asked about X before starting", "Loaded reference Y"
   - **[Outcome]**: Is the result correct and complete?
     Examples: "File contains field Z", "Tests pass"
   - **[Compliance]**: Did the agent obey all skill instructions?
     Examples: "Followed all phases in order", "Did self-review"
   Each criterion must be:
   - Binary (pass/fail, no "partially")
   - Observable (from agent's messages and created files)
   - Specific (no "did a good job", no "output is correct")
   - Skill-focused (testing skill behavior, not general agent quality)

5. **Model**: "Which model should the runners use? Opus for complex tasks
   (coding, architecture), Sonnet for simpler ones (documentation, notes)."

6. **Persona**: Keep the default persona from
   [scenario-format.md](references/scenario-format.md) as-is. Modify only
   when the user explicitly requests changes. For edge-case scenarios, add
   modifications to the default persona:
   - Brief/vague responses
   - Contradictory requirements
   - Changing mind mid-conversation

**Checkpoint:** All scenarios have: task prompt, acceptance criteria, model
choice. User approved final set.

## Phase 3: Save Scenarios

1. Create directory: `~/.claude/skill-tests/{skill-name}/scenarios/`
2. Save each scenario as a separate .md file:
   - happy-path.md
   - edge-case-1.md, edge-case-2.md, etc.
3. Format each scenario file using the template from
   [scenario-format.md](references/scenario-format.md)
   (structure, persona block, grading notes)
4. If the scenario needs supporting files (task files, mock data),
   create them in the same scenarios/ directory
5. Confirm to user: "Scenarios saved at [path]. Run skill-tester to execute."

**Checkpoint:** All scenario files saved. Paths confirmed to user.

## Final Check

Before finishing, verify:
- [ ] Target skill fully read (SKILL.md + all references)
- [ ] Each scenario has task prompt, persona, acceptance criteria, grading notes
- [ ] Acceptance criteria are binary, observable, specific, skill-focused
- [ ] All scenario files saved to `~/.claude/skill-tests/{skill-name}/scenarios/`
- [ ] User confirmed all scenarios
