marta.expose()
marta.plugin({id="es¦tab", name="Close Duplicated Tabs", apiVersion="2.2"})

marta.action({id="✗tab_n_dupe"	, name="Tab: ✗Close Current & Duplicates"
  ,apply                      	= function(ctxA) tabCloseNLeft(ctxA); tabCloseDupe({ctxA=ctxA,saveCur=true}); end})
marta.action({id="✗dupe"      	, name="Tab: ✗Close Duplicates"
  ,apply                      	= function(ctxA)                      tabCloseDupe({ctxA=ctxA,saveCur=true}); end})
--marta.action({id="✗tab_cur←"	, name="Tab: ✗Close Current and switch to the ←Left",
--   apply                    	= function(ctxA) tabClose(ctxA); tabLeft(ctxA); end})
--marta.action({id="✗tab_cur" 	,name="Tab: ✗Close Current"
  -- ,apply                   	= function(ctxA) tabClose    (ctxA); end})
--marta.action({id="tab←"     	,name="Tab: Switch to the ←Left"
  -- ,apply                   	= function(ctxA) tabLeft     (ctxA); end})
local _d = 0

function tabCloseNLeft(ctxA) -- move selection ← after tab close (by default it shifts →) unless ours is the right-most
  local ctxW    	= ctxA.window
  local tabMan  	= ctxW.tabs
  local paneMan 	= ctxW.panes
  local tabA    	= paneMan.activePane -- get uptodate active tab
  local tabSide 	= tabMan:getPosition      (tabA)    -- tab ←position→      (tab:PaneContext):Option<TabPosition>
  local tabCount	= tabMan:getCount         (tabSide) -- tab count for a given position	--(pos:Option<TabPosition>):Int
  local tabActI 	= tabMan:getActiveTabIndex(tabSide) -- 0-based active tab index
  local tabL0I  	= tabMan:getTab(tabSide,0         ).tabIndex -- ‹most  tab index
  local tabR0I  	= tabMan:getTab(tabSide,tabCount-1).tabIndex --  most› tab index

  if (tabCount == 1) then tabMan:close(tabA); return end -- no adjustment needed for just a single tab

  if     (tabActI == tabL0I) then -- no left-adjustment needed since post-close there will be no ‹tab
    tabMan:close(tabA)
  elseif (tabActI == tabR0I) then -- no left-adjustment needed since post-close the tab selection will move left
    tabMan:close(tabA)
  else -- close active tab then move selection left
    tabMan:close(tabA)
    if (tabActI > 0) then -- this might not be needed since left-most tab receiving -1 command doesn't error
      local tabLeft	= tabMan:getTab         (tabSide, tabActI-1)
      tabMan:activate(tabLeft)
    end
  end
end

function tabLeft(ctxA)
  local ctxW   	= ctxA.window
  local tabMan 	= ctxW.tabs
  local paneMan	= ctxW.panes
  local tabA   	= paneMan.activePane -- get uptodate active tab
  local tabSide	= tabMan:getPosition      (tabA)  --(tab: PaneContext): Option<TabPosition> -- Get the tab ←position→
  local tabActI	= tabMan:getActiveTabIndex(tabSide) -- 0-based active tab index
  local tabLeft	= tabMan:getTab           (tabSide, tabActI-1)
  if (tabActI > 0) then -- this might not be needed since left-most tab receiving -1 command doesn't error
    tabMan:activate(tabLeft)
  end
end

function tabClose(ctxA)
  local ctxW   	= ctxA.window
  local tabMan 	= ctxW.tabs
  local paneMan	= ctxW.panes
  local tabA   	= paneMan.activePane
  tabMan:close(tabA)
end

function tabCloseDupe(arg)
  local saveCur	= arg.saveCur or false -- if current tab is a dupe, close the other dupe

  local ctxA   	= arg.ctxA
  local ctxW   	= ctxA.window
  local tabMan 	= ctxW.tabs
  local paneMan	= ctxW.panes

  local tabA     	= paneMan.activePane
  local tabSide  	= tabMan:getPosition(tabA)    -- the tab ←position→            	--(tab:PaneContext):Option<TabPosition>
  local tabCount 	= tabMan:getCount   (tabSide) -- tab count for a given position	--(pos:             Option<TabPosition>):Int
  local tabA_path	= tabA.model.folder.path      -- tab unique Path (≠String, use rawValue for that)
  local t        	= {}
  local i        	= 0
  if saveCur then t[tabA_path.rawValue]={true,tabA.id} end -- save current tab's path/ID to not close it later
  if _d >= 3 then martax.alert("Active tab's ID=\n" .. tabA.id .. "\nwith path@=" .. tabA_path) end

  while (i < tabCount) do
    local tab    	 = tabMan:getTab(tabSide, i)
    local path_s 	 = tab.model.folder.path.rawValue
    if (t[path_s]	~= nil) then
      if saveCur and (tab.id == tabA.id) then -- don't close if current tab is our original active tab
        if _d >= 3 then martax.alert("Saving active tab ID=\n" .. tabA.id .. "\npath=" .. tabA_path) end
        i	= i + 1
      else
        if _d >= 3 then martax.alert("Closing tab with ID=\n" .. tab.id) end
        tabMan:close(tab)
        tabCount	 = tabCount - 1 -- reuse index (it can be a ←moved tab), decrease the # of iters from the top
      end
    else
      t[path_s]	= {true,tab.id} -- path has been seen @ ID (use it later to close i instead of my active tab)
      i        	= i + 1
    end
  end
  if saveCur then -- activate our original active tab as focus shifts on tab close (bug)
    tabMan:activate(tabA)
  end
end
