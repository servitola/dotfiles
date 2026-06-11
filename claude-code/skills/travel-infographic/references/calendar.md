# Calendar: даты + цены

Схема данных для `gen_calendar.py` (`dates_calendar.png`) — юзер гибок
±5+ дней, цены гуляют.

## Схема данных

```json
{
  "title": "string",
  "route": "LCA → AER",
  "year": 2026,
  "month": 9,
  "prices": {"2026-09-01": 28000, "2026-09-02": 31000, ...}
}
```
