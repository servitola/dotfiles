printf 'Json reading'
jq 'map(.caps_lock[0].key)' ./data/data.json