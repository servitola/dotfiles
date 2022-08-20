if spoon.Griddle then
    spoon.Griddle:bindHotkeys({ enter = { ctrlAndAlt, "m" } })
    print("Griddle binded its keys")
    spoon.Griddle:start()
end