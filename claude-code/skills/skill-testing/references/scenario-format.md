# Scenario File Format

## Template

```markdown
# Scenario: {name}

## Type
happy-path | edge-case

## Task Prompt
(Natural language, exactly as user would type. No test framework boilerplate.)

## Persona

Default — do not change unless user explicitly asks:

Предприниматель, занимается vibe-coding через Claude Code. Не программист —
не знает синтаксис, библиотеки, алгоритмы. Есть техническое образование,
понимает продукты и архитектуру на уровне "что делает что". Общается прямо,
без воды.

Edge-case modifications (only for edge-case scenarios):
(add specific persona changes here, e.g.)
- Даёт противоречивые ответы
- Меняет требования в середине
- Отвечает "ну сделай как-нибудь" даже на продуктовые вопросы

## Persona Answer Sheet

Anticipated questions the skill will ask, with in-character answers.

Rules for the runner:
- (a) a question not covered here → make the most persona-consistent
  assumption and log it in journal.md under "Assumed answers";
- (b) at any user-approval checkpoint (the skill says "present to user",
  "wait for confirmation") → assume approval and log
  `ASKED-USER "{checkpoint}" → assumed approval`.

Authoring rule: answers contain persona facts and data only — never
procedural hints about what the skill should do next (the same sheet goes
to the baseline runner).

Example Q/A pairs:
- Q: "Какой стек предпочитаете?" → A: "Без разницы, что проще поддерживать.
  Я не программист."
- Q: "Нужна ли авторизация?" → A: "Да, вход через Google, без паролей."
- Q: "Какой дедлайн / приоритет?" → A: "Не горит, главное чтобы работало."
- Q: "Где хранить данные?" → A: "Не знаю, выбери сам что-то простое."
- Q: "Подтвердите план" → assumed approval (rule (b)).

## Side Effects

redirect (default) | allow-with-cleanup: {paths}

Redirect covers both absolute paths and relative paths (relative writes
would land in the orchestrator's cwd).
External/irreversible effects are never authorized by this field — they go
through the user-facing gate.
For allow-with-cleanup: list the exact paths and the cleanup step.

## Acceptance Criteria
(number depends on skill complexity — simple skills may have 5,
complex procedural skills can have 15+)

Format:
1. [Process] {observable behavior during execution}
2. [Outcome] {observable result in files/messages}
3. [Compliance] {skill instruction that must be followed}

Each criterion:
- Binary: pass or fail, no "partially"
- Observable: checkable from journal entries and created files
- Specific: no subjective assessments
- Skill-focused: tests skill behavior, not general agent quality

## Grading Notes
- Which skill phases to verify and in what order
- Which references the skill says to read (verify runner read them)
- How to check time-dependent criteria (e.g., TDD order)
- What file contents to verify (not just file existence)
- Which artifacts prove which criteria (outcome criteria are graded from
  artifacts only)
```

## Prompt Examples

### One-shot skill (task-manager):
Поставь задачу на завтра: купить продукты в 10:00, уведомление за 30 минут.

### Coding skill (code-writing):
Реализуй задачу: ~/.claude/skill-tests/code-writing/scenarios/task-1.md

### Dialogue skill (user-spec-planning):
Хочу добавить авторизацию через Google в мобильное приложение.

### Informational skill (methodology):
Как правильно организовать работу с ветками в git?
