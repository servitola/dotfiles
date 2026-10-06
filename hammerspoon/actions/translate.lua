-- PopupTranslateSelection:bindHotkeys binds by itself; calling
-- translateSelectionPopup keeps the registry the only binding path.
return function(register)
    register("translate_to_russian", function() spoon.PopupTranslateSelection:translateSelectionPopup("ru") end)
    register("translate_to_english", function() spoon.PopupTranslateSelection:translateSelectionPopup("en") end)
    register("translate_to_greek", function() spoon.PopupTranslateSelection:translateSelectionPopup("el") end)
end
