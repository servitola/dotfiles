# Route map / Route GIF: один маршрут

Схема данных для `gen_route_map.py` (статичная карта `route_<from>_<to>_map.png`)
и `gen_route_gif.py` (анимация `route_<from>_<to>_animated.gif`). Формат общий.

## Схема данных

```json
{
  "title": "Лимасол → Армавир (через Сочи)",
  "stops": [
    {"name": "Лимасол",  "type": "start"},
    {"name": "Ларнака (LCA)", "type": "airport"},
    {"name": "Сочи (AER)",   "type": "airport"},
    {"name": "Армавир", "type": "end"}
  ],
  "segments": [
    {"from_idx": 0, "to_idx": 1, "mode": "car",    "duration_h": 1.5, "label": "Такси"},
    {"from_idx": 1, "to_idx": 2, "mode": "flight", "duration_h": 3.0, "label": "Pegasus"},
    {"from_idx": 2, "to_idx": 3, "mode": "train",  "duration_h": 6.0, "label": "Поезд 643Г"}
  ],
  "total_hours": 10.5,
  "total_price_rub": 28000
}
```

## Координаты

Координаты `lat`/`lon` для известных городов берутся из `_cities.json`. Если города нет — добавь поле явно: `{"name": "Foo", "lat": 12.34, "lon": 56.78}`.
