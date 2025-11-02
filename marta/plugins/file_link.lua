marta.expose()
local plugID = "es¦file"
marta.plugin({id=plugID, name="File actions", apiVersion="2.2"})

marta.action({id="symlink",name="Symlink🔗 to the currently selected items in-place"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="sym"  ,target="self"})  ; end})
marta.action({id="symlink_op",name="Symlink🔗 to the currently selected items @ the opposite tab"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="sym"  ,target="opp"})  ; end})
marta.action({id="alias"  ,name="Alias⤻ link to the currently selected items in-place"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="alias",target="self"}); end})
-- marta.action({id="alias_op",name="Alias⤻ link to the currently selected items @ the opposite tab"  ,
-- crashes ↑ on "reopen", ↓ shorter name seems fine
marta.action({id="alias_op",name="Alias ⤻ link to the currently selected items @ the opposite tab"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="alias",target="opp"}); end})
marta.action({id="hardlink",name="Hardlink⤑ to the currently selected items in-place"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="hard" ,target="self"}) ; end})
marta.action({id="hardlink_op",name="Hardlink⤑ to the currently selected items @ the opposite tab"  ,
  isApplicable = function(ctxA) return ctxA.activePane.model.hasActiveFiles end,
  apply        = function(ctxA) symlink({ctxA=ctxA,linkT="hard" ,target="opp"}) ; end})

local cfgID    	= "link"
local cfgKeyPre	 = plugID ..'.'.. cfgID
marta.configurationKey("behavior","actions",cfgKeyPre .. ".affixSym", {
  description	= "Icon for a symbolic link affix (d̳e̳f̳)",
  examples   	= {"🔗̳","🖇"}         , typeConstraints={"string"}})
marta.configurationKey("behavior","actions",cfgKeyPre .. ".affixAlias", {
  description	= "Icon for an alias affix (d̳e̳f̳)",
  examples   	= {"⤻̳","⤺","⤴"}      , typeConstraints={"string"}})
marta.configurationKey("behavior","actions",cfgKeyPre .. ".affixHard", {
  description	= "Icon for an alias affix (d̳e̳f̳)",
  examples   	= {"⤑̳","→","⇢"}      , typeConstraints={"string"}})
marta.configurationKey("behavior","actions",cfgKeyPre .. ".spot", {
  description	= "Affix location: ⎀pre.ext, stem⎀.ext,  post.ext⎀ (d̳e̳f̳)",
  examples   	= {"pre","s̳t̳e̳m̳","post"}, typeConstraints={"string"} })
marta.configurationKey("behavior","actions",cfgKeyPre .. ".maxLinkNo", {
  description	= "Create links unless selected more than this # of items (0=∞)",
  examples   	= {"1̳","5","0"}        , typeConstraints={"int"} })
marta.configurationKey("behavior","actions",cfgKeyPre .. ".maxIterNo", {
  description	= "When link path exists, try this # of times to change the name by adding 1,2,3,... (d̳e̳f̳)",
  examples   	= {"5̳","0"}            , typeConstraints={"int"} })
marta.configurationKey("behavior","actions",cfgKeyPre .. ".binAlias", {
  description	= "Full path to the 'alisma' binary for creating aliases",
  examples   	= {"/usr/local/bin/alisma"}, typeConstraints={"string"} })
marta.configurationKey("behavior","actions",cfgKeyPre .. ".binHard", {
  description	= "Full path to the 'ln' binary for creating hardlinks",
  examples   	= {"/bin/ln"}          , typeConstraints={"string"} })

local _d = 0
local illegalFS = "[*:\"\\|<>/?^]" -- Win+Mac, remove these from user string input for compatibility
function symlink(arg)
  local ctxA    	= arg.ctxA             	-- holds refs to PaneContext instances for active+inactive panes
  local ctxG    	= marta.globalContext  	--
  local fsL     	= marta.localFileSystem	--
  local ctxPA   	= ctxA.activePane      	--
  local ctxP_inA	= ctxA.inactivePane    	--
  local model   	= ctxPA.model          	-- Active pane list model
  local viewP   	= ctxPA.view           	--
  local filesInf	= model.activeFileInfos	-- array of FileInfo with all the attributes, gathered on folder load (so cached) (ZIP fs doesn't store macOS extended attributes)
  local parentFd	= model.folder         	--

  function pss(msg) viewP:showNotification(msg,plugID,"short") end -- short-term "print" to the statusbar
  function psl(msg) viewP:showNotification(msg,plugID,"long" ) end -- long-term  "print" to the statusbar

  -- Get info about InActive pane
  local model_inA,parentFd_inA
  if ctxP_inA   	~= nil then
    model_inA   	= ctxP_inA.model  -- InActive pane list model
    parentFd_inA	= model_inA.folder end

  local ctxW	= ctxA.window
  local actG	= ctxG.actions

  -- Get and validate user configuration values
  local cfgDef,cfgPath,cfgBeh,cfgAct,cfgSym,cfgAls,cfgSpot,cfgMaxLnk,cfgIterMax,cfgAlsP,cfgHrdP,linkT,target,affix
  local affixSym,affixAlias,maxLnk,binAlias,binHard,r_spot                           ,r_linkT,r_affix

  cfgDef      	 = {["affixSym"]='🔗',["affixAlias"]='⤻',["affixHard"]='⤑',["spot"]='stem',["lnkMax"]=1,["iterMax"]=5
   ,          	   ["linkT"]="sym",["target"]="self",["binAlias"]='/usr/local/bin/alisma',["binHard"]='/bin/ln',}
  r_spot      	 = {["pre"]=true,["stem"] =true,["post"]=true} -- all possible spot values
  r_linkT     	 = {["sym"]=true,["alias"]=true,["hard"]=true} -- all possible link values
  cfgAct      	 = ctxG:get("behavior","actions") -- crashes without the extra path element
  if cfgAct   	~= nil then
    cfgSym    	 = cfgAct[cfgKeyPre .. ".affixSym"  ]
    cfgAls    	 = cfgAct[cfgKeyPre .. ".affixAlias"]
    cfgHard   	 = cfgAct[cfgKeyPre .. ".affixHard" ]
    cfgSpot   	 = cfgAct[cfgKeyPre .. ".spot"      ]
    cfgLnkMax 	 = cfgAct[cfgKeyPre .. ".maxLinkNo" ]
    cfgIterMax	 = cfgAct[cfgKeyPre .. ".maxIterNo" ]
    cfgAlsP   	 = cfgAct[cfgKeyPre .. ".binAlias"  ]
    cfgHrdP   	 = cfgAct[cfgKeyPre .. ".binHard"   ] end
  affixSym    	 = cfgSym     or cfgDef['affixSym'  ]
  affixAlias  	 = cfgAls     or cfgDef['affixAlias']
  affixHard   	 = cfgHard    or cfgDef['affixHard' ]
  spot        	 = cfgSpot    or cfgDef['spot'      ]
  lnkMax      	 = cfgLnkMax  or cfgDef['lnkMax'    ]
  iterMax     	 = cfgIterMax or cfgDef['iterMax'   ]
  binAlias    	 = cfgAlsP    or cfgDef['binAlias'  ]
  binHard     	 = cfgHrdP    or cfgDef['binHard'   ]
  linkT       	 = arg.linkT  or cfgDef['linkT'     ]
  target      	 = arg.target or cfgDef['target'    ]
  local _sa = " argument, using ≝'"
  if (type(affixSym)  	~= "string"           	)                                                 	--
    then   affixSym   	 = cfgDef['affixSym'  	]; pss("❗link: wrong '"..cfgKeyPre..".affixSym'"  	.._sa..cfgDef['affixSym'].."'")
  else     affixSym   	 = affixSym:gsub      	(illegalFS,"")                                    	end
  if (type(affixAlias)	~= "string"           	)                                                 	--
    then   affixAlias 	 = cfgDef['affixAlias'	]; pss("❗link: wrong '"..cfgKeyPre..".affixAlias'"	.._sa..cfgDef['affixAlias'].."'")
  else affixAlias     	 = affixAlias:gsub    	(illegalFS,"")                                    	end
  if (type(affixHard) 	~= "string"           	)                                                 	--
    then   affixHard  	 = cfgDef['affixHard' 	]; pss("❗link: wrong '"..cfgKeyPre..".affixHard'" 	.._sa..cfgDef['affixHard'].."'")
  else     affixHard  	= affixHard:gsub      	(illegalFS,"")                                    	end
  if (type(spot)      	~= "string"           	)                                                 	--
    or (r_spot[spot]  	== nil                	)                                                 	--
    then   spot       	 = cfgDef['spot'      	]; pss("❗link: wrong '"..cfgKeyPre..".spot'"      	.._sa..cfgDef['spot'].."'"    ) end
  if (type(lnkMax)    	~= "number"           	)                                                 	--
    or (not           	isint(lnkMax)         	)                                                 	--
    then   lnkMax     	 = cfgDef['lnkMax'    	]; pss("❗link: wrong '"..cfgKeyPre..".maxLinkNo'" 	.._sa..cfgDef['lnkMax'].."'"  ) end
  if (type(iterMax)   	~= "number"           	)                                                 	--
    or (not           	isint(iterMax         	)                                                 	--
    or (   iterMax    	< 0)                  	)                                                 	--
    then   iterMax    	 = cfgDef['iterMax'   	]; pss("❗link: wrong '"..cfgKeyPre..".maxIterNo'" 	.._sa..cfgDef['iterMax'].."'" ) end
  if (type(linkT)     	~= "string"           	)                                                 	--
    or (r_linkT[linkT]	== nil                	)                                                 	--
    then   linkT      	 = cfgDef['linkT'     	]; pss("❗link: wrong 'linkT' action"              	.._sa..cfgDef['linkT'].."'"    ) end
  if (type(binAlias)  	~= "string"           	)                                                 	--
    then   binAlias   	 = cfgDef['binAlias'  	]; pss("❗link: wrong '"..cfgKeyPre..".binAlias'"  	.._sa..cfgDef['binAlias'].."'") end
  if (type(binHard)   	~= "string"           	)                                                 	--
    then   binHard    	 = cfgDef['binHard'   	]; pss("❗link: wrong '"..cfgKeyPre..".binHard'"   	.._sa..cfgDef['binHard'].."'") end
  r_affix = {["sym"]=affixSym,["alias"]=affixAlias,["hard"]=affixHard} -- all possible affix values
  affix   = r_affix[linkT] -- set affix to the matching link type
  if _d	>= 3 then martax.alert("Config vs Validated",(cfgSym or '✗') ..'|'.. (cfgAls or '✗') ..'|'.. (cfgSpot or '✗') ..'|'.. (cfgLnkMax or '✗')
    .."\n".. (affixSym or 'a') ..'|'.. (affixAlias or 'l') ..'|'.. (spot or 's') ..'|'.. (tostring(lnkMax) or 'l')) end

  local countFI = #filesInf
  if      countFI == 0 then return                 -- skip an empty dir (no files)
  elseif (countFI  > lnkMax) and (lnkMax > 0) then -- avoid mass link creation
    pss(tostring(countFI) .. " items selected, more than 'maxLinkNo' of '" ..lnkMax.."'"); return; end
  if not parentFd then return; end                       	-- skip root?
  if not parentFd.fileSystem:supports("writeAccess") then	-- skip paths w/o write access
    pss("❗link: Can't create a link here, file system is read only"                ); return; end
  if target == "opp" then
    if not parentFd_inA then	-- inactive pane is not a folder
      pss("❗link: Can't create a link @ the opposite tab, it's not a folder"       ); return; end
    if not parentFd_inA.fileSystem:supports("writeAccess") then	-- skip paths w/o write access
      pss("❗link: Can't create a link @ the opposite tab, file system is read only"); return; end
  end

  local symMode = martax.access("rwxr-xr-x") -- o755 or 493; though doesn't matter for symlinks
  local alsMode = martax.access("rw-r--r--") -- o644 or 420; not sure it matters for aliases either

  for _, tgtFI in ipairs(filesInf) do        -- Iterate thru active=(selected¦cursor) files
    if     tgtFI.isSymbolicLink    then      -- skip existing symlinks
      pss("❗link: Item already a link: "..affixSym); return
    elseif tgtFI.isAlias           then      -- ...       and aliases
      pss("❗link: Item already a link: "..affixAlias); return; end
    -- elseif tgtFI.hardLinkCount > 1 then      -- ...       and hardlinks
      -- viewP:showNotification("❗link: Item already a link: "..affixHard,plugID,"short"); return; end

    local tgtPath,tgtName,tgtStem,tgtExt
    local lnkPath,lnkName,lnkStem,lnkExt,lnkParentFd
    tgtPath	= tgtFI.path.rawValue
    tgtName	= tgtFI.name
    tgtStem	= parentFd:append(tgtName).nameWithoutExtension -- tgtFI.nameWithoutExtension
    tgtExt 	= tgtFI.extension
    dtgtExt	= tgtExt~='' and ('.'..tgtExt) or tgtExt

    local isFail	= nil
    local last  	= iterMax + 1                   -- add one more step to signal failure
    for i=0,last do
      if i == last then isFail = true; break; end -- signal the loop failure to the post-loop code
      local n = tostring((i>0 and i) or '')       -- index to add to affix on subsequent tries (1st try is '')

      -- construct the link file path by appending symbol target name
      if target == "opp" then lnkParentFd	= parentFd_inA -- InActive pane tab
      else                    lnkParentFd	= parentFd end -- Active   ...

      if     (spot == 'pre' ) then lnkF = lnkParentFd:append(affix..n..tgtName)
      elseif (spot == 'stem') then lnkF = lnkParentFd:append(          tgtStem..affix..n..dtgtExt)
      elseif (spot == 'post') then lnkF = lnkParentFd:append(          tgtName..affix..n)
      else pss("❗link: wrong 'spot' validation"); return; end
      lnkPath  	= lnkF.path.rawValue
      if _d    	>= 3 then
        lnkName	= lnkF.name
        lnkStem	= lnkF.nameWithoutExtension
        lnkExt 	= lnkF.extension
        martax.alert("Target vs Link", '\ntgtPath='..tgtPath .. '\ntgtName='..tgtName .. '\ntgtStem='..tgtStem .. '\ndtgtExt='..dtgtExt
          ..'\n'.. '\nlnkPath='..lnkPath .. '\nlnkName='..lnkName .. '\nlnkStem='..lnkStem .. '\nlnkExt='..lnkExt)
      end
      if lnkF:exists() then goto continue; end -- try a new name skipping link creation

      if     linkT == "sym"   then
        local err = lnkF:makeSymbolicLink(tgtPath, symMode)
        if err then psl("❗link: " .. err.description)
        else        break; end
      elseif linkT == "alias" then
        if fsL:get(binAlias):exists() then
          martax.execute(binAlias,{"-a",tgtPath,lnkPath}); break
        else psl("❗link: missing binary @ " .. binAlias); return; end
      elseif linkT == "hard"  then
        if fsL:get(binHard):exists() then
          martax.execute(binHard,{     tgtPath,lnkPath}); break
        else psl("❗link: missing binary @ " .. binHard); return; end
      end
      ::continue::
    end
    if lnkF:exists() and isFail then -- looped thru the end and didn't find any empty paths
      pss("❗link: "..last.." paths taken up to: " .. lnkPath); return; end
  end
end

function isempty(s) return s == nil or s == '' end
function isint  (n) return n == math.floor(n)  end
