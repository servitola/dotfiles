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

## Acceptance Criteria
(number depends on skill complexity)

Format:
1. [Process] {observable behavior during execution}
2. [Outcome] {observable result in files/messages}
3. [Compliance] {skill instruction that must be followed}

Each criterion:
- Binary: pass or fail, no "partially"
- Observable: checkable from messages and files
- Specific: no subjective assessments
- Skill-focused: tests skill behavior, not general agent quality

## Grading Notes
- Which skill phases to verify and in what order
- Which references the skill says to read (verify runner read them)
- How to check time-dependent criteria (e.g., TDD order)
- What file contents to verify (not just file existence)

### Model for this test
{opus | sonnet} (agreed with user during design)
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
