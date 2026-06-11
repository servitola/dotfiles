# Timeline / Cost: список вариантов (старый формат)

Схема данных для `gen_timeline.py` (`compare_timeline.png`) и
`gen_cost.py` (`cost_breakdown.png`).

## Схема данных

```json
{
  "title": "string",
  "options": [
    {
      "label": "string (короткое имя варианта)",
      "legs": [{"type": "flight|train|transfer|layover|bus|car", "label": "string", "hours": float}],
      "total_hours": float,
      "total_price_rub": int,
      "cost_breakdown": {"base": int, "taxes": int, "bag": int, "seat": int}
    }
  ]
}
```

`legs` и `total_hours` обязательны для `gen_timeline`. `cost_breakdown` обязателен для `gen_cost`.

## Полный пример вызова

```bash
# Записать данные в JSON
cat > /tmp/trip.json << 'EOF'
{
  "title": "Лимасол → Армавир, 1 сентября",
  "options": [
    {
      "label": "Через Сочи + поезд",
      "legs": [
        {"type": "transfer", "label": "Дом → LCA", "hours": 1.5},
        {"type": "flight",   "label": "LCA → IST", "hours": 2.5},
        {"type": "layover",  "label": "Стамбул",   "hours": 4.0},
        {"type": "flight",   "label": "IST → AER", "hours": 3.5},
        {"type": "transfer", "label": "AER → жд", "hours": 1.0},
        {"type": "train",    "label": "Сочи → Армавир", "hours": 6.0}
      ],
      "total_hours": 18.5,
      "total_price_rub": 28000
    }
  ]
}
EOF

# Запустить
~/projects/dotfiles/claude-code/skills/travel-infographic/gen_timeline.py \
  --data /tmp/trip.json \
  --out /tmp/compare_timeline.png
```
