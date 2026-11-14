; findLabels.il -- 3.53
; CIW and popup show the search mode as mode=CURRENT or
; mode=CURRENT TO BOTTOM: save lines and result lines of findSchLay() and
; findLaySch(), and the first line of the summary window.
; 3.52:
; Smaller marks: donut outer radius 0.8 (inner 0.4); candidate box + X
; half size 0.4 (flCandidateHalf, a quarter of before). Block outline
; boxes are unchanged.
; Endpoint whose pin is not found and that is not a placed block here
; (e.g. a nand drawn flat with lvn/lvp, no A/B labels): no pin is guessed;
; its instance-name label (I12) is marked and a warning names the pin.
; "Use CURRENT TO BOTTOM" is kept only for a real block instance (layout
; cell with the schematic cell name or a name variant, not a PCell).
; 3.51:
; PCell labels: the small terminal texts inside PCells (D, S, G of lvn/lvp)
; are no longer taken as net or instance names (flSkipPCellLabels). A net
; named D or S is found only on real labels. Terminal marks still use them.
; MOS source/drain are swappable in layout (flSwapPins): a D or S terminal
; of a PCell instance gets a box + X on both D and S, and the CIW says so.
; CURRENT: when some pins were skipped because they are inside a block
; (e.g. I12 nand2), the CIW names those blocks even if other pins were
; marked (use CURRENT TO BOTTOM for them).
; 3.50:
; Smaller donuts (flDonutOuter 1.6, flDonutInner 0.4). Highlight colors in
; the order of flColorOrder: pink, orange, yellow, green, blue, purple,
; white, then the rest; also for schematic probes (KP_3). Colors are
; matched by the display color names in each site's display.drf.
; First mark color: the highlight layer whose display color is pink or
; magenta comes first (see flColorOrder); flFirstLPP can force a layer.
; Below the edit cell, mosaic elements and units inside a bundle get a
; box + X again (easier to see). A block box shared by several bits
; (Imain<0>..<7>) is drawn once.
; Bundle cells: a layout cell named <cell>_x<N> (e.g. a_saio_x2) that holds
; the cell directly stands for it (e.g. 8 a_saio placed as a 1x4 mosaic of
; a_saio_x2). In the edit cell the bundle is selected; below it, every
; inner a_saio gets a plain box (bit order is not known).
; KP_3 on a layout instance or mosaic (e.g. a_saiox8): its cell name is
; saved. In the schematic the instances of that cell (same name, or a name
; variant for blocks) are found: in the searched cell they are selected
; (other selections cleared); CURRENT TO BOTTOM also probes them below.
; Instance target found by cell name: mosaics count too (e.g. a_saiox8
; placed as a 1x8 mosaic). In the edit cell the mosaic is selected; below
; it, every mosaic element gets a plain box (bit order is not known).
; When a block is found this way, the layout selection is cleared first and
; only the found blocks stay selected.
; Clear key moved from KP_9 to the keypad dot: KP_Decimal (NumLock on) and
; KP_Delete (NumLock off, same key).
; Endpoint with no instance-name label: when exactly one layout instance
; of its schematic cell (same name or name variant) is inside that block
; and it has the pin label, the pin gets the donut. Otherwise no box: the
; CIW names the cell, e.g. "Idogrp (a_dogrp) has no instance-name label in
; /I0 - not marked"; the popup shows it only when nothing was marked.
; Large blocks: block placement checks and block descents are cached, so a
; net spread over a large block (e.g. a test-mode signal) no longer hangs.
; Time limit flTimeoutSeconds (8 s): the pin guide (S2L) or the schematic
; walk and trace (L2S) stops there; the marks found so far stay and the
; popup says so. The whole search stops at twice that time (failed).
; The CIW result line shows the time taken.
; L2S BOTTOM: a target not in the searched cell is looked up below only in
; the schematic of the layout cell the labels were saved in (a_dogrp), and
; traced from there; other cells by name only when that cell is not found.
; wire_model (N1 <-> N2) is a pass-through cell like netcon / wire_couple.
; Previous selections in a cellview no longer shown in a window are not
; deselected (avoids GE-2106 warnings).
; Name variants (crc_gen_xxx, xxx_crc_gen) are one candidate set; parts
; placed inside another candidate (crc_gen_u01 in temp_crc_gen) are dropped.
; A net label in the saved cell's layout replaces that cell's own terminal
; marks; endpoints are looked up only inside the saved cell when found.
; Cell names: same name, else crc_gen_xxx, else xxx_crc_gen (block cells),
; for block layouts, the saved cell and instance targets.
; Inside a block, a label with the net's inner name (CRCRD for csm_CRCRD)
; is marked instead of the terminals.
; BOTTOM: endpoint instances are looked up in the layout of the schematic
; cell the targets were saved in (crc_gen) first, so auto names (I59) of
; other cells are not used. Net labels are still found everywhere.
; Short CIW and popup: one line per problem, e.g.
; "CRC_BD_ERR: not in this cell (inside crc_gen, crc_reg). Use CURRENT TO
; BOTTOM."; trace and skip details only with flVerbose=t.
; L2S BOTTOM: a target found as a net in the searched cell is not searched
; again by name in lower cells (only traced by connectivity).
; Trace starts only at the searched cell (not at same-name nets found in
; lower cells); UP only on the outside chain, never from a DOWN net.
; L2S trace: the found net is followed under other names - netcon /
; wire_couple (both modes); into block cells by pin bit and up to the
; parent cell when entered by descend (CURRENT TO BOTTOM). CIW: NETCON,
; DOWN, UP lines with the full path.
; L2S follows pass-through cells (flNetconCells): netcon (any pair) and
; wire_couple (N1 <-> N2 only); probed in the same color (CIW: NETCON a = b).
; Instance target found by cell name: selected, no Edit Properties window;
; the CIW shows Name, Library and Cell.
; Block endpoints at the saved level are followed into the block even when
; a block instance-name label (Icrc_gen) is in the layout: the label is
; ignored. CURRENT: the block is not the edit cell -> NOT IN THIS CELL.
; BOTTOM: the block's net label if present, else the inner terminals.
; Instance target with no instance-name label: the layout instance of the
; same cell is selected (Name, Library, Cell in the CIW); a block cell may
; carry a suffix (crc_gen_temp).
; BOTTOM: placements below the edit cell get a box + X instead.
; CURRENT: a block endpoint whose pin is not in the edit cell is not marked
; on its instance-name label; the popup says to use CURRENT TO BOTTOM.
; Block = a cell whose schematic holds sub-cells with their own schematic.
; Required-terminal guidance, regardless of routing connectivity.
; KP_1 supports layout edit-in-place.
; Schematic instance pins (red squares) are captured as their external nets.
; CURRENT TO BOTTOM layout search also descends into simple mosaics.
; Layout hierarchy is expanded only where a result can exist.
; Endpoints without an instance-name label (blocks) are followed into the
; block: its net label if present, otherwise the terminals of the devices
; inside. A net label found in a block suppresses terminal marks in that
; whole block, including blocks nested in it.
; Block layout: same cell name first, else the share of block instance
; names found as labels (flBlockMatchMin).
; Endpoints in bus units: instance labels are followed into the unit
; (same name or same base name, e.g. I25<7> -> I25<0>) down to the pin.
; Duplicate instance-name labels are narrowed by the required pin label;
; remaining instances are shown as CANDIDATE marks (box + X).
; The popup reports target-level problems only; traversal notes stay in CIW.
; Option cells (M?RES marker) and resistor PCells (P1RES) are used
; symmetrically, so the donut goes on their instance-name label only.
; Option ON/OFF is the presence of the matching MET layer inside the master;
; it is compared with the schematic property r and mismatches are warned.
; Highlight colors fall back to marker size when only one color is available.
; An instance-name label inside a large cell (guard ring, well) and a small
; cell is resolved to the cell that has the pin.
; When an instance is identified but its pin position is not, the
; instance-name label itself gets the donut (LABEL ONLY in CIW).
; Mosaics (e.g. stacked resistors) are identified per element: the element
; whose area holds the instance-name label is used.
; The summary window is modeless and opens only for problems the marks
; cannot show: nothing marked, an endpoint with no mark at all, an option
; ON/OFF mismatch, or a failed search. A target that is not found at all
; opens it only when the whole search marked nothing. Other warnings stay
; in the CIW.
; It closes by itself after flSummaryCloseSeconds.
; An endpoint on a block that has no instance-name label in the layout is
; followed into the block's schematic (both modes). The block's layout is
; the cell with the same cell name, else the cell holding most of the block
; schematic's instance names as labels (>= flBlockMatchMin). Below the
; first level a block must be placed inside its parent block's layout, so
; auto names (I0, I3, ...) of unrelated cells are never used. Blocks that
; are not in the searched layout are skipped with a CIW note.
; CURRENT marks only inside the edit cell: a block reached through the
; schematic counts only when the edit cell itself is that block's layout.
; CIW output is short by default; flVerbose=t prints the full trace.
; flPrintLastReport() always has every line of the last run.
; Temporary visuals only. Default bindkeys (KP_1/3/Decimal/2) are set at load;
; set flSetBindKeys=nil before loading to keep your own.

unless(boundp('flHilightRecords) flHilightRecords=nil)
unless(boundp('flProbeRecords) flProbeRecords=nil)
unless(boundp('flSelectionRecords) flSelectionRecords=nil)
unless(boundp('flSummaryBox) flSummaryBox=nil)
unless(boundp('flSummarySerial) flSummarySerial=0)
unless(boundp('flSummaryOpen) flSummaryOpen=nil)

; Block cells (schematic made of sub-cells), cached per load.
flBlockCellCache=makeTable('flBlockCellCache nil)

flVersion="3.53"
flBottomMode=nil
flSchTargets=nil
flLayTargets=nil
flSourceCell=nil
flSourceLib=nil
flLaySourceCell=nil
flLayCellTargets=nil
flLastReport=nil

flAutoZoom=t
; t: print every trace line (BLOCK, REQUIRED, DESCEND, counters).
flVerbose=nil
flShowWarningPopup=t
flDetailLimit=20
flWarningLimit=20
flPopupLines=5
flMaxDepth=64
flMaxVisits=100000
flDonutOuter=0.8
flDonutInner=0.4
; Half size of the candidate box + X (terminal candidates).
flCandidateHalf=0.4
flSchViewName="schematic"
flFindMissingByPins=t
flTraverseMosaics=t
flPinDescendLimit=4
; Schematic levels followed below an unlabeled block endpoint (BOTTOM mode).
flSchDescendLimit=6
; Summary window closes by itself after this many seconds (0 = stays open).
flSummaryCloseSeconds=5
; Time limit in seconds (0 = none). The pin guide (S2L) or the schematic
; walk and trace (L2S) stops here and the marks found so far stay; the whole
; search stops at twice this time.
flTimeoutSeconds=8
; Block schematic -> layout cell: same cell name first (t), then labels.
flUseCellNameMatch=t
; Share of a block schematic's instance names that must be labels in the
; layout cell (0..1).
flBlockMatchMin=0.5
; Instance target without an instance-name label: select the layout
; instance of the same cell (blocks: also "<cell>_<suffix>", e.g.
; crc_gen_temp); the CIW shows its Library, Cell and Name.
flSelectCellByName=t
; L2S: also probe nets passed through these cells (e.g. TMBIT<0> =
; ICAMTMBIT<2> through netcon).
; Entry "cell": any terminal to any other terminal (2-terminal cells).
; Entry list("cell" "A" "B"): only terminal A <-> terminal B; the others
; are not followed (wire_couple: N1 <-> N2; B is the coupled neighbor).
flFollowNetcons=t
flNetconCells=list(
    "netcon"
    list("wire_couple" "N1" "N2")
    list("wire_model" "N1" "N2")
)
; L2S CURRENT TO BOTTOM: follow the net into block cells by pin bit
; (flTraceDown) and up to the parent cell when the schematic was entered by
; descend (flTraceUpLevels levels). At most flTraceMaxNets extra nets.
flTraceDown=t
flTraceUpLevels=2
flTraceMaxNets=50

flIdentityLabelLayers=list("ITXT" "M1TXT")
flTerminalLabelLayers=list("ITXT" "M1TXT")

; Labels inside PCell masters are terminal texts (D, S, G), not net or
; instance names: skip them in name searches. They are still read for
; terminal positions.
flSkipPCellLabels=t

; Terminal pairs that may be swapped in layout (MOS source/drain). On a
; PCell instance both terminals of a pair are boxed as candidates.
; Set to nil to mark only the schematic terminal.
flSwapPins=list(list("D" "S"))

; Geometry terminals for cells that carry no pin labels.
; Edit this block for another process or project.
flUseGeometryTerminals=t
; Option marker layer and the metal layer that makes the option ON.
flOptionLayers=list(
    list("M1RES" "MET1")
    list("M2RES" "MET2")
    list("M3RES" "MET3")
)
; Resistor body layer, and the master-level cell that forms a resistor end.
flResistorLayers=list("P1RES")
flResistorEndCells=list("cont")
; Masters with more instances than this are treated as ordinary blocks.
flGeometryMaxInstances=6
; Schematic property read for the option state (SPICE style value):
; at or below flOptionOnMaxOhm is ON, at or above flOptionOffMinOhm is OFF.
flOptionProp="r"
flOptionOnMaxOhm=1.0
flOptionOffMinOhm=1.0e6
flSchInstances=nil

flProbeOrder=nil
flProbeLPPs=list(
    list("y0" "drawing") list("y1" "drawing")
    list("y2" "drawing") list("y3" "drawing")
    list("y4" "drawing") list("y5" "drawing")
    list("y6" "drawing") list("y7" "drawing")
    list("y8" "drawing") list("y9" "drawing")
)

; Highlight colors are used in this order, by the display color name of
; each highlight layer (y0..y9); colors matching none come last.
; flShowColors() lists the layers, their colors and the order used.
flColorOrder=list(
    list("pink" "magenta" "rose" "fuchsia")
    list("orange")
    list("yellow" "gold")
    list("green" "lime")
    list("blue" "cyan" "navy" "sky")
    list("purple" "violet" "lavender" "plum")
    list("white")
)
; Optional: this layer first anyway, e.g. list("y5" "drawing").
flFirstLPP=nil

procedure(flModeName()
    if(flBottomMode then "CURRENT TO BOTTOM" else "CURRENT")
)

; "A, B, C, +5 more"
procedure(flNameListText(names)
    prog((text count)
        text=""
        count=0

        foreach(n names
            when(count<6
                text=strcat(text if(count>0 then ", " else "") n)
            )
            count=count+1
        )

        when(count>6
            text=strcat(text sprintf(nil ", +%d more" count-6))
        )

        return(text)
    )
)

; Trace line: kept for flPrintLastReport(), printed only with flVerbose.
procedure(flDetail(message)
    flDetails=cons(message flDetails)

    when(flVerbose
        if(flDetailCount<flDetailLimit then
            printf("%s\n" message)
            flDetailCount=flDetailCount+1
        else
            flDetailOmitted=flDetailOmitted+1
        )
    )
)

; Verbose-only message outside a search.
procedure(flTrace(message)
    when(flVerbose printf("%s\n" message))
    t
)

; Target-level problem: counted, saved, shown in the popup.
procedure(flWarn(message)
    flWarnings=cons(message flWarnings)
    flWarningCount=flWarningCount+1
    when(flWarningCount<=flWarningLimit
        printf("%s\n" message)
    )
    flPartial=t
)

; Problem the marks cannot show: also opens the summary window.
procedure(flAlert(message)
    flWarn(message)
    flAlerts=cons(message flAlerts)
    flAlertCount=flAlertCount+1
    t
)

; Target not found: opens the summary window only when nothing at all
; was marked in this search (e.g. a lone terminator instance).
procedure(flSoftAlert(message)
    flWarn(message)
    flSoftAlerts=cons(message flSoftAlerts)
    flSoftCount=flSoftCount+1
    t
)

; Traversal-level information: CIW and report only, no popup by itself.
; quiet=t: kept for the report, printed only with flVerbose.
procedure(flNote(message @optional quiet)
    unless(member(message flNotes)
        flNotes=cons(message flNotes)

        when(!quiet || flVerbose
            printf("%s\n" message)
        )
    )
    t
)

procedure(flPrintLastReport()
    foreach(message flLastReport
        printf("%s\n" message)
    )
    t
)

procedure(flExpand(name)
    prog((r names)
        unless(stringp(name) && strlen(name)>0
            return(nil)
        )
        r=errset(dbProduceMemName(name) nil)
        unless(r && listp(car(r)) && car(r)
            return(nil)
        )
        names=car(r)
        foreach(n names
            unless(stringp(n) && strlen(n)>0
                return(nil)
            )
        )
        return(names)
    )
)

procedure(flContains(expression name)
    expression==name || member(name flExpand(expression))
)

procedure(flName(obj)
    prog((r)
        r=errset(obj~>name nil)
        return(if(r && stringp(car(r)) then car(r) else nil))
    )
)

procedure(flNetName(obj)
    prog((r)
        r=errset(obj~>net~>name nil)
        return(if(r && stringp(car(r)) then car(r) else nil))
    )
)

procedure(flPinSymbolP(obj)
    prog((r)
        r=errset(obj~>master~>cellName nil)
        return(r && member(car(r) list("ipin" "opin" "iopin")))
    )
)

procedure(flText(obj)
    prog((r a)
        when(obj~>objType=="label"
            return(obj~>theLabel)
        )
        when(obj~>objType=="textDisplay"
            r=errset(obj~>associate nil)
            when(r
                a=car(r)
                return(flName(a) || flNetName(a))
            )
        )
        return(nil)
    )
)

procedure(flTarget(obj)
    prog((name r pin a)
        when(obj~>objType=="inst"
            unless(flPinSymbolP(obj)
                return(list('inst obj~>name obj))
            )

            r=errset(obj~>pin nil)
            when(r pin=car(r))
            name=flNetName(pin) || flNetName(obj) || flName(pin)

            when(name return(list('port name)))
            return(nil)
        )

        when(obj~>objType=="textDisplay"
            r=errset(obj~>associate nil)
            when(r && car(r)
                a=car(r)
                when(a~>objType=="inst"
                    return(flTarget(a))
                )
            )
        )

        name=flNetName(obj)
        when(name return(list('net name)))

        name=flText(obj)
        when(name return(list('text name)))

        when(obj~>objType=="term"
            return(list('port obj~>name))
        )

        when(obj~>objType=="pin"
            r=errset(obj~>term~>name nil)
            when(r && stringp(car(r))
                return(list('port car(r)))
            )
        )

        return(nil)
    )
)

; Return (scalar-instance/pin-pairs error-message).
procedure(flEndpointInfo(cv name @optional (remember t))
    prog((r sig records it pos width im pm pairs)
        r=errset(dbFindSigByName(cv name) nil)
        unless(r && car(r)
            return(list(nil "No exact schematic signal"))
        )

        sig=car(r)
        r=errset(sig~>memInstTerms nil)
        unless(r
            return(list(nil "Cannot read schematic terminals"))
        )

        records=car(r)

        foreach(rec records
            unless(listp(rec) && length(rec)>=2
                return(list(nil "Unsupported terminal record"))
            )

            it=car(rec)
            pos=cadr(rec)

            unless(it && numberp(pos) && pos>=0
                return(list(nil "Invalid terminal member position"))
            )

            r=errset(dbGetNameNumBit(it~>name) nil)
            unless(r && numberp(car(r)) && car(r)>0
                return(list(nil "Cannot resolve terminal width"))
            )

            width=car(r)

            r=errset(
                dbGetMemName(it~>inst~>name fix(pos/width))
                nil
            )
            unless(r && stringp(car(r))
                return(list(nil "Cannot resolve scalar instance"))
            )
            im=car(r)

            r=errset(
                dbGetMemName(it~>name mod(pos width))
                nil
            )
            unless(r && stringp(car(r))
                return(list(nil "Cannot resolve scalar pin"))
            )
            pm=car(r)

            unless(member(list(im pm) pairs)
                pairs=cons(list(im pm) pairs)
            )

            when(remember
                flRememberInstance(it~>inst im)
            )
        )

        return(list(reverse(pairs) nil))
    )
)

; Edit-cell instance that owns a figure selected through an instance.
procedure(flPathOwner(cv fig path)
    prog((all found r cand master owners)
        all=cv~>instances

        foreach(step path
            cand=if(listp(step) then car(step) else step)
            r=errset(cand~>objType nil)

            when(r && car(r)=="inst" && member(cand all)
                unless(member(cand found)
                    found=cons(cand found)
                )
            )
        )

        when(length(found)==1
            return(car(found))
        )

        r=errset(fig~>cellView nil)
        master=if(r then car(r) else nil)

        foreach(inst found
            when(master && inst~>master==master
                owners=cons(inst owners)
            )
        )

        return(if(length(owners)==1 then car(owners) else nil))
    )
)

; Terminal name of a selected symbol pin figure, or of its pin label.
procedure(flFigPinName(fig)
    prog((r)
        r=errset(fig~>pin~>term~>name nil)
        when(r && stringp(car(r)) return(car(r)))

        r=errset(fig~>term~>name nil)
        when(r && stringp(car(r)) return(car(r)))

        r=errset(fig~>pin~>name nil)
        when(r && stringp(car(r)) return(car(r)))

        r=errset(
            if(fig~>objType=="label" then fig~>theLabel else nil)
            nil
        )
        when(r && stringp(car(r)) return(car(r)))

        return(nil)
    )
)

; External net on inst/pinName. The instTerm name is the terminal name.
procedure(flInstPinNet(inst pinName)
    prog((name)
        foreach(it inst~>instTerms
            when(!name && it~>name==pinName
                name=flNetName(it)
            )
        )
        return(name)
    )
)

; Instance pins selected in the schematic (the red squares).
; They are not in geGetSelSet(); geGetObjectSelectedSet() returns
; entries shaped like (pinFigure ((instance 0 0 0))).
; Do not use the internal symbol terminal name as the external net name.
; Return (targets ownerInstanceNames entryCount).
procedure(flSelectedPinTargets(cv)
    prog((r recs targets owners fig path type inst pinName name)
        r=errset(geGetObjectSelectedSet(hiGetCurrentWindow()) nil)

        unless(r && car(r)
            r=errset(geGetObjectSelectedSet() nil)
        )

        recs=if(r && listp(car(r)) then car(r) else nil)

        foreach(rec recs
            fig=if(listp(rec) then car(rec) else rec)
            path=if(listp(rec) then cadr(rec) else nil)
            unless(listp(path) path=list(path))

            r=errset(fig~>objType nil)
            type=if(r then car(r) else nil)
            inst=nil
            pinName=nil
            name=nil

            if(type=="instTerm" then
                r=errset(fig~>inst nil)
                inst=if(r then car(r) else nil)
                pinName=flName(fig)
                name=flNetName(fig)
            else
                when(path
                    inst=flPathOwner(cv fig path)
                    pinName=flFigPinName(fig)

                    when(inst && pinName
                        name=flInstPinNet(inst pinName)
                    )
                )
            )

            cond(
                (name
                    unless(member(list('net name) targets)
                        targets=cons(list('net name) targets)
                    )

                    when(inst && !member(flName(inst) owners)
                        owners=cons(flName(inst) owners)
                    )

                    flTrace(sprintf(nil
                        "[S2L] PIN %L/%L -> net=%L"
                        flName(inst) pinName name
                    ))
                )

                (path || type=="instTerm"
                    flTrace(sprintf(nil
                        "[S2L] PIN-SELECT unresolved: type=%L cell=%L pin=%L owner=%L path=%L"
                        type
                        car(errset(fig~>cellView~>cellName nil))
                        pinName
                        flName(inst)
                        path
                    ))
                )
            )
        )

        return(list(reverse(targets) owners length(recs)))
    )
)

; Block cell: its schematic holds sub-cells that have their own schematic
; (crc_gen made of flip-flops), not only primitive devices (a standard
; cell made of transistors). Cached per load.
procedure(flBlockCellP(lib cell)
    prog((key cached r cv found)
        unless(stringp(lib) && stringp(cell) return(nil))

        key=strcat(lib "/" cell)
        cached=flBlockCellCache[key]
        when(cached return(cached=='yes))

        when(ddGetObj(lib cell flSchViewName)
            r=errset(dbOpenCellViewByType(lib cell flSchViewName "" "r") nil)
            cv=if(r then car(r) else nil)

            when(cv
                foreach(inst cv~>instances
                    when(
                        !found &&
                        !flPinSymbolP(inst) &&
                        ddGetObj(inst~>libName inst~>cellName flSchViewName)

                        found=t
                    )
                )
            )
        )

        flBlockCellCache[key]=if(found then 'yes else 'no)
        return(found)
    )
)

; (cellName isBlock) of a selected schematic instance.
procedure(flInstCellInfo(inst)
    prog((r lib cell)
        r=errset(list(inst~>libName inst~>cellName) nil)
        unless(r return(nil))

        lib=car(car(r))
        cell=cadr(car(r))
        unless(stringp(cell) return(nil))

        return(list(cell car(errset(flBlockCellP(lib cell) nil))))
    )
)

procedure(flCaptureSch(cv)
    prog((sel pinInfo target seen info raw cell)
        flSchTargets=nil
        flSchInstances=nil
        flSourceCell=cv~>cellName
        flSourceLib=cv~>libName

        sel=geGetSelSet()
        pinInfo=flSelectedPinTargets(cv)

        foreach(obj sel
            target=flTarget(obj)

            when(target
                if(
                    car(target)=='inst &&
                    member(cadr(target) cadr(pinInfo))
                then
                    flTrace(sprintf(nil
                        "[S2L] Instance %L replaced by its selected pin."
                        cadr(target)
                    ))
                else
                    raw=cons(target raw)
                )
            )
        )

        raw=append(
            reverse(raw)
            car(pinInfo)
        )

        foreach(target raw
            foreach(name flExpand(cadr(target))
                unless(member(list(car(target) name) seen)
                    seen=cons(list(car(target) name) seen)
                    info=list(nil nil)
                    cell=nil

                    if(car(target)=='inst then
                        when(caddr(target)
                            cell=flInstCellInfo(caddr(target))
                        )
                    else
                        info=flEndpointInfo(cv name)
                    )

                    ; (kind name pairs reason cellInfo)
                    flSchTargets=cons(
                        list(
                            car(target)
                            name
                            car(info)
                            cadr(info)
                            cell
                        )
                        flSchTargets
                    )
                )
            )
        )

        flSchTargets=reverse(flSchTargets)

        when(flSchTargets
            printf(
                "[S2L] mode=%s; saved %s\n"
                flModeName()
                flNameListText(mapcar('cadr flSchTargets))
            )
        )

        foreach(rec flSchTargets
            flTrace(sprintf(nil
                "[S2L] TARGET kind=%L name=%L endpoints=%L"
                car(rec) cadr(rec) caddr(rec)
            ))
        )

        unless(flSchTargets
            printf(
                "[S2L] Nothing saved. Select a wire, net label, instance, or instance pin.\n"
            )
            flTrace(sprintf(nil
                "[S2L] Selection debug: selSet=%L objectSelSet=%d"
                sel~>objType
                caddr(pinInfo)
            ))
        )

        return(flSchTargets!=nil)
    )
)

procedure(flCaptureLay()
    prog((r cell)
        flLayTargets=nil
        flLaySourceCell=nil
        flLayCellTargets=nil

        foreach(obj geGetSelSet()
            ; Instance or mosaic (a block): saved by its cell name.
            when(member(obj~>objType list("inst" "mosaic"))
                cell=flFigCellName(obj)

                when(stringp(cell) && !member(cell flLayCellTargets)
                    flLayCellTargets=cons(cell flLayCellTargets)
                )
            )

            when(obj~>objType=="label"
                ; Layout cell that holds the label (crc_gen, a_dogrp, ...).
                unless(flLaySourceCell
                    r=errset(obj~>cellView~>cellName nil)
                    flLaySourceCell=if(r then car(r) else nil)
                )

                foreach(name flExpand(obj~>theLabel)
                    unless(member(name flLayTargets)
                        flLayTargets=cons(name flLayTargets)
                    )
                )
            )
        )

        flLayTargets=reverse(flLayTargets)
        flLayCellTargets=reverse(flLayCellTargets)

        if(flLayTargets || flLayCellTargets then
            printf(
                "[L2S] mode=%s; saved %s\n"
                flModeName()
                flNameListText(
                    append(
                        flLayTargets
                        mapcar(
                            lambda((c) strcat("cell " c))
                            flLayCellTargets
                        )
                    )
                )
            )
        else
            printf("[L2S] Nothing saved. Select layout labels or instances.\n")
        )

        return(flLayTargets || flLayCellTargets)
    )
)

; Cell name of a layout instance or mosaic, or nil.
procedure(flFigCellName(fig)
    prog((info r)
        when(fig~>objType=="inst"
            return(car(errset(fig~>cellName nil)))
        )

        info=flMosaicInfo(fig)
        when(info
            return(car(errset(car(info)~>cellName nil)))
        )

        r=errset(car(fig~>instanceList)~>cellName nil)
        return(if(r then car(r) else nil))
    )
)

; Schematic instance inst is of layout cell layCell: same cell name, or
; for a block a name variant (crc_gen <- crc_gen_xxx, xxx_crc_gen).
procedure(flSchCellMatch(inst layCell)
    prog((cell n m)
        cell=inst~>cellName
        unless(stringp(cell) && stringp(layCell) return(nil))
        when(cell==layCell return(t))

        n=strlen(cell)
        m=strlen(layCell)
        unless(m>n+1 return(nil))

        unless(
            or(
                substring(layCell 1 n+1)==strcat(cell "_")
                substring(layCell m-n n+1)==strcat("_" cell)
            )

            return(nil)
        )

        return(car(errset(flBlockCellP(inst~>libName cell) nil)))
    )
)

; Some instance of a saved layout cell is at or below schematic cv.
procedure(flCellsBelow(cv stack)
    prog((key state found child)
        key=strcat(cv~>libName "/" cv~>cellName)
        state=flCellsBelowTable[key]

        when(state=='yes return(t))
        when(state return(nil))
        when(member(key stack) return(nil))
        when(flSoftTimeUp() return(nil))

        flCellsBelowTable[key]='pending

        foreach(inst cv~>instances
            when(!found && inst~>objType=="inst" && !flPinSymbolP(inst)
                foreach(cell flLayCellTargets
                    when(flSchCellMatch(inst cell) found=t)
                )

                unless(found
                    child=car(errset(flChildSchematic(inst) nil))

                    when(child && child!=cv && flCellsBelow(child cons(key stack))
                        found=t
                    )
                )
            )
        )

        flCellsBelowTable[key]=if(found then 'yes else 'no)
        return(found)
    )
)

; Layout cell targets in schematic cv: instances of the cell are selected
; in the searched cell (depth 0) and probed below it (BOTTOM).
procedure(flWalkCells(cv path ownerBBox depth stack win)
    prog((key index hit child)
        when(flSoftTimeUp() return(nil))

        when(flVisits>=flMaxVisits || depth>flMaxDepth
            flTraversalLimited=t
            return(nil)
        )

        key=list(cv~>libName cv~>cellName cv~>viewName)

        when(member(key stack)
            flTraversalLimited=t
            return(nil)
        )

        flVisits=flVisits+1

        foreach(inst cv~>instances
            when(inst~>objType=="inst" && !flPinSymbolP(inst)
                hit=nil
                index=length(flLayTargets)

                foreach(cell flLayCellTargets
                    when(!hit && flSchCellMatch(inst cell)
                        hit=t
                        flMarkFound(strcat("cell " cell))

                        if(depth==0 then
                            unless(member(inst flCellSelected)
                                flCellSelected=cons(inst flCellSelected)
                            )

                            flCellSelects=flCellSelects+1
                            flResultBBox=flUnion(flResultBBox inst~>bBox)

                            flNote(sprintf(nil
                                "[L2S] cell %s: selected %s (%s)"
                                cell inst~>name inst~>cellName
                            ))
                        else
                            when(flProbe(win flJoin(path inst~>name) nil index)
                                flResultBBox=flUnion(
                                    flResultBBox
                                    ownerBBox || inst~>bBox
                                )
                            )

                            flNote(sprintf(nil
                                "[L2S] cell %s: probed %s (%s)"
                                cell flJoin(path inst~>name) inst~>cellName
                            ))
                        )
                    )

                    index=index+1
                )

                ; BOTTOM: go down only where a saved cell is below (not
                ; into a found block itself).
                when(flBottomMode && !hit
                    child=car(errset(flChildSchematic(inst) nil))

                    when(child && child!=cv && flCellsBelow(child cons(key stack))
                        foreach(memberName flExpand(inst~>name)
                            flWalkCells(
                                child
                                flJoin(path memberName)
                                ownerBBox || inst~>bBox
                                depth+1
                                cons(key stack)
                                win
                            )
                        )
                    )
                )
            )
        )

        return(t)
    )
)

procedure(flUnion(a b)
    cond(
        (!a b)
        (!b a)
        (t
            list(
                list(
                    min(caar(a) caar(b))
                    min(cadar(a) cadar(b))
                )
                list(
                    max(caadr(a) caadr(b))
                    max(cadadr(a) cadadr(b))
                )
            )
        )
    )
)

procedure(flCenter(bb)
    list(
        (caar(bb)+caadr(bb))/2.0
        (cadar(bb)+cadadr(bb))/2.0
    )
)

procedure(flInside(p bb)
    bb && car(p)>=caar(bb) && car(p)<=caadr(bb) &&
    cadr(p)>=cadar(bb) && cadr(p)<=cadadr(bb)
)

procedure(flJoin(path name)
    if(path=="/" || path=="" then
        strcat("/" name)
    else
        strcat(path "/" name)
    )
)

; True when the figure's cellview is shown in a window (a figure of a
; closed window cannot be deselected and only causes a GE warning).
procedure(flFigShown(fig)
    prog((r cv)
        r=errset(fig~>cellView nil)
        cv=if(r then car(r) else nil)
        unless(cv return(nil))

        r=errset(geGetCellViewWindow(cv) nil)
        ; Function not available: try to deselect as before.
        unless(r return(t))
        return(car(r)!=nil)
    )
)

procedure(flClearOwned(direction)
    prog((keep)
        foreach(rec flHilightRecords
            if(!direction || car(rec)==direction then
                errset(
                    when(geIsValidHilightSet(cadr(rec))
                        geDeleteHilightSet(cadr(rec))
                    )
                    nil
                )
            else
                keep=cons(rec keep)
            )
        )

        flHilightRecords=reverse(keep)
        keep=nil

        foreach(rec flProbeRecords
            if(!direction || car(rec)==direction then
                errset(
                    geDeleteProbe(cadr(rec) caddr(rec))
                    nil
                )
            else
                keep=cons(rec keep)
            )
        )

        flProbeRecords=reverse(keep)
        keep=nil

        foreach(rec flSelectionRecords
            if(!direction || car(rec)==direction then
                when(flFigShown(cadr(rec))
                    errset(geDeselectFig(cadr(rec)) nil)
                )
            else
                keep=cons(rec keep)
            )
        )

        flSelectionRecords=reverse(keep)
        return(t)
    )
)

procedure(flSelect(fig)
    if(fig~>objType=="label" then
        flSelLabelCount=flSelLabelCount+1
    else
        flSelInstCount=flSelInstCount+1
    )

    unless(geIsFigSelected(fig)
        geSelectFig(fig)
        flSelectionRecords=cons(
            list('S2L fig)
            flSelectionRecords
        )
    )
)

; CIW: each highlight layer, its display color and the order used.
; Usage: flShowColors()
procedure(flShowColors()
    prog((cv tf r lp packet)
        cv=geGetEditCellView()
        tf=if(cv then techGetTechFile(cv) else nil)
        unless(tf
            printf("[FINDER] Open a layout first.\n")
            return(nil)
        )

        foreach(lpp flProbeLPPs
            r=errset(techGetLP(tf lpp) nil)
            lp=if(r then car(r) else nil)
            packet=nil

            when(lp
                r=errset(drGetPacket("display" techGetLPPacketName(lp)) nil)
                packet=if(r then car(r) else nil)
            )

            printf("[FINDER] %L color=%L\n" lpp if(packet then nth(5 packet) else "?"))
        )

        printf("[FINDER] order used: %L\n" flPalette(cv))
        return(t)
    )
)

procedure(flPalette(cv)
    prog((tf out used r lp packet color colors sorted)
        tf=techGetTechFile(cv)
        unless(tf return(nil))

        foreach(lpp flProbeLPPs
            r=errset(techGetLP(tf lpp) nil)

            when(r && car(r)
                lp=car(r)

                r=errset(
                    drGetPacket("display" techGetLPPacketName(lp))
                    nil
                )

                when(r && car(r)
                    packet=car(r)
                    color=nth(5 packet)

                    unless(member(color used)
                        used=cons(color used)
                        out=cons(lpp out)
                        colors=cons(list(lpp color) colors)
                    )
                )
            )
        )

        ; Order by color: pink, orange, yellow, green, blue, purple, rest.
        colors=reverse(colors)
        sorted=nil

        foreach(group flColorOrder
            foreach(rec colors
                when(
                    !member(car(rec) sorted) &&
                    stringp(cadr(rec)) &&
                    exists(want group rexMatchp(want lowerCase(cadr(rec))))

                    sorted=append(sorted list(car(rec)))
                )
            )
        )

        foreach(rec colors
            unless(member(car(rec) sorted)
                sorted=append(sorted list(car(rec)))
            )
        )

        when(flFirstLPP && member(flFirstLPP sorted)
            sorted=cons(flFirstLPP remove(flFirstLPP sorted))
        )

        flDetail(sprintf(nil "[FINDER] highlight order %L" sorted))
        return(sorted)
    )
)

procedure(flHilight(cv lpp direction)
    prog((hs)
        hs=geCreateHilightSet(cv lpp nil)

        when(hs
            hs~>enable=t
            flHilightRecords=cons(
                list(direction hs)
                flHilightRecords
            )
        )

        return(hs)
    )
)

; S2L results are calculated in edit-cell coordinates.
; Convert only when displaying them in the window cellview.
procedure(flDisplayPoint(point)
    if(flEIP then
        geEditToWindowPoint(flSearchWindow point)
    else
        point
    )
)

procedure(flDisplayBBox(bb)
    prog((out p)
        unless(bb return(nil))

        foreach(corner
            list(
                car(bb)
                cadr(bb)
                list(caar(bb) cadadr(bb))
                list(caadr(bb) cadar(bb))
            )

            p=flDisplayPoint(corner)
            out=flUnion(out list(p p))
        )

        return(out)
    )
)

; Confirmed location: donut + guide line.
procedure(flMark(hs point bb)
    prog((p origin)
        p=flDisplayPoint(point)
        origin=flDisplayPoint(0:0)

        geAddHilightDonut(
            hs p flDonutOuter*flMarkScale flDonutInner
        )
        geAddHilightLine(hs list(origin p))

        flResultBBox=flUnion(
            flResultBBox
            flDisplayBBox(bb)
        )

        flMatches=flMatches+1
        return(t)
    )
)

; Candidate location: box + X + guide line, same color as the target.
procedure(flMarkCandidate(hs point)
    prog((p origin s x y)
        p=flDisplayPoint(point)
        origin=flDisplayPoint(0:0)
        s=flCandidateHalf*flMarkScale
        x=car(p)
        y=cadr(p)

        geAddHilightLine(hs list(list(x-s y-s) list(x+s y-s)))
        geAddHilightLine(hs list(list(x+s y-s) list(x+s y+s)))
        geAddHilightLine(hs list(list(x+s y+s) list(x-s y+s)))
        geAddHilightLine(hs list(list(x-s y+s) list(x-s y-s)))
        geAddHilightLine(hs list(list(x-s y-s) list(x+s y+s)))
        geAddHilightLine(hs list(list(x-s y+s) list(x+s y-s)))
        geAddHilightLine(hs list(origin p))

        flResultBBox=flUnion(
            flResultBBox
            flDisplayBBox(list(point point))
        )

        flMatches=flMatches+1
        return(t)
    )
)

procedure(flZoom(win)
    prog((bb mx my)
        unless(flAutoZoom && flResultBBox return(nil))

        bb=flResultBBox
        mx=max(flDonutOuter 2.0 (caadr(bb)-caar(bb))*0.20)
        my=max(flDonutOuter 2.0 (cadadr(bb)-cadar(bb))*0.20)

        hiUpdate()

        errset(
            hiZoomIn(
                win
                list(
                    list(caar(bb)-mx cadar(bb)-my)
                    list(caadr(bb)+mx cadadr(bb)+my)
                )
            )
            nil
        )

        return(t)
    )
)

; Return (allLabels identityLabels) for one layout cellview, cached per run.
; True when master is a PCell (submaster or super master).
procedure(flPCellP(master)
    prog((r)
        unless(master return(nil))

        r=errset(master~>superMaster nil)
        when(r && car(r) return(t))

        r=errset(master~>isParamCell nil)
        when(r && car(r) return(t))

        return(nil)
    )
)

procedure(flLayoutIndex(cv)
    prog((cached labels identities)
        cached=flIndexTable[cv]
        when(cached return(cached))

        ; PCell texts (D, S, G) are terminal markers, not names.
        when(flSkipPCellLabels && flPCellP(cv)
            cached=list(nil nil)
            flIndexTable[cv]=cached
            return(cached)
        )

        foreach(fig cv~>shapes
            when(fig~>objType=="label"
                labels=cons(fig labels)

                when(member(fig~>layerName flIdentityLabelLayers)
                    identities=cons(fig identities)
                )
            )
        )

        cached=list(labels identities)
        flIndexTable[cv]=cached
        return(cached)
    )
)

; Return (master xy orient rows columns uX uY name) for a simple mosaic,
; or nil when the mosaic cannot be expanded safely.
procedure(flMosaicInfo(m)
    prog((r type il master orient vals name)
        r=errset(m~>mosaicType nil)
        type=if(r then car(r) else nil)
        when(stringp(type) && type!="simple"
            return(nil)
        )

        r=errset(m~>instanceList nil)
        il=if(r then car(r) else nil)
        when(listp(il) && length(il)>1
            return(nil)
        )

        r=errset(m~>master nil)
        master=if(r then car(r) else nil)
        when(!master && il
            r=errset(car(il)~>master nil)
            master=if(r then car(r) else nil)
        )

        r=errset(m~>orient nil)
        orient=if(r then car(r) else nil)
        when(!stringp(orient) && il
            r=errset(car(il)~>orient nil)
            orient=if(r then car(r) else nil)
        )
        unless(stringp(orient) orient="R0")

        r=errset(list(m~>xy m~>rows m~>columns m~>uX m~>uY) nil)
        unless(r return(nil))
        vals=car(r)

        unless(
            master &&
            listp(nth(0 vals)) &&
            fixp(nth(1 vals)) && nth(1 vals)>0 &&
            fixp(nth(2 vals)) && nth(2 vals)>0 &&
            numberp(nth(3 vals)) &&
            numberp(nth(4 vals))

            return(nil)
        )

        r=errset(m~>name nil)
        name=if(r && stringp(car(r)) then car(r) else "mosaic")

        return(list(
            master
            nth(0 vals)
            orient
            nth(1 vals)
            nth(2 vals)
            nth(3 vals)
            nth(4 vals)
            name
        ))
    )
)

; Child placement records of one layout master:
;   ('inst   master transform name)
;   ('mosaic master xy orient rows columns uX uY name)
procedure(flChildRecords(cv)
    prog((records r master info type)
        foreach(inst cv~>instances
            type=inst~>objType

            cond(
                (type=="inst"
                    r=errset(inst~>master nil)
                    master=if(r then car(r) else nil)

                    when(master
                        records=cons(
                            list('inst master inst~>transform inst~>name)
                            records
                        )
                    )
                )
                (type=="mosaic" || type=="mosaicInst"
                    nil
                )
                (t
                    flUnsupported=flUnsupported+1
                )
            )
        )

        foreach(m cv~>mosaics
            info=if(flTraverseMosaics then flMosaicInfo(m) else nil)

            if(info then
                records=cons(cons('mosaic info) records)
            else
                flUnsupported=flUnsupported+1
            )
        )

        return(reverse(records))
    )
)

procedure(flChildList(cv)
    car(flChildTable[cv])
)

; Visit every unique layout master once (BOTTOM only).
procedure(flCollectMasters(cv depth stack)
    prog((records)
        when(member(cv stack)
            flTraversalLimited=t
            return(nil)
        )

        when(flChildTable[cv]
            return(t)
        )

        when(flMasterCount>=flMaxVisits || depth>flMaxDepth
            flTraversalLimited=t
            return(nil)
        )

        flHardTimeCheck()
        flMasterCount=flMasterCount+1
        flMasters=cons(cv flMasters)

        records=flChildRecords(cv)
        flChildTable[cv]=list(records)

        foreach(rec records
            flCollectMasters(cadr(rec) depth+1 cons(cv stack))
        )

        return(t)
    )
)

; A master is relevant when it holds a target-name label or is a chosen block.
procedure(flOwnRelevant(cv)
    prog(()
        when(member(cv flScopeSet)
            return(t)
        )

        ; Parent of a cell searched for an instance target (BOTTOM).
        when(flCellTargets
            foreach(rec flChildList(cv)
                when(member(cadr(rec) flCellTargets)
                    return(t)
                )
            )
        )

        foreach(label car(flLayoutIndex(cv))
            when(stringp(label~>theLabel) && flNameTable[label~>theLabel]
                return(t)
            )
        )

        return(nil)
    )
)

procedure(flNeeded(cv)
    prog((state result)
        state=flNeedTable[cv]

        when(state=='yes
            return(t)
        )

        when(state
            return(nil)
        )

        flNeedTable[cv]='pending
        result=flOwnRelevant(cv)

        foreach(rec flChildList(cv)
            when(!result && flNeeded(cadr(rec))
                result=t
            )
        )

        flNeedTable[cv]=if(result then 'yes else 'no)
        return(result)
    )
)

; Expand placements (including mosaic elements) only into relevant subtrees.
procedure(flExpandOccurrences(cv transform path depth)
    prog((child xy rows cols ux uy row col tr)
        when(flVisits>=flMaxVisits || depth>flMaxDepth
            flTraversalLimited=t
            return(nil)
        )

        flVisits=flVisits+1
        flHardTimeCheck()

        flOccurrences=cons(
            list(cv transform path depth)
            flOccurrences
        )

        foreach(rec flChildList(cv)
            child=cadr(rec)

            when(flNeeded(child)
                if(car(rec)=='inst then
                    flExpandOccurrences(
                        child
                        dbConcatTransform(nth(2 rec) transform)
                        flJoin(path nth(3 rec))
                        depth+1
                    )
                else
                    xy=nth(2 rec)
                    rows=nth(4 rec)
                    cols=nth(5 rec)
                    ux=nth(6 rec)
                    uy=nth(7 rec)
                    row=0

                    while(row<rows
                        col=0

                        while(col<cols
                            if(flVisits<flMaxVisits then
                                tr=list(
                                    list(
                                        car(xy)+col*ux
                                        cadr(xy)+row*uy
                                    )
                                    nth(3 rec)
                                    1.0
                                )

                                flExpandOccurrences(
                                    child
                                    dbConcatTransform(tr transform)
                                    flJoin(
                                        path
                                        sprintf(nil "%s[%d,%d]"
                                            nth(8 rec) row col
                                        )
                                    )
                                    depth+1
                                )

                                col=col+1
                            else
                                flTraversalLimited=t
                                col=cols
                                row=rows
                            )
                        )

                        row=row+1
                    )
                )
            )
        )

        return(t)
    )
)

procedure(flIdentityNames(pairs)
    prog((names)
        foreach(pair pairs
            unless(member(car(pair) names)
                names=cons(car(pair) names)
            )
        )
        return(names)
    )
)

procedure(flIdentityCount(cv names)
    prog((seen)
        foreach(label cadr(flLayoutIndex(cv))
            when(member(label~>theLabel names)
                unless(member(label~>theLabel seen)
                    seen=cons(label~>theLabel seen)
                )
            )
        )
        return(length(seen))
    )
)

; Number of distinct names of table tbl found as identity labels in cv.
procedure(flIdentityCountT(cv tbl)
    prog((seen n)
        seen=makeTable('flCountSeen nil)
        n=0

        foreach(label cadr(flLayoutIndex(cv))
            when(tbl[label~>theLabel] && !seen[label~>theLabel]
                seen[label~>theLabel]=t
                n=n+1
            )
        )

        return(n)
    )
)

; Masters placed anywhere below master `from` (a table), built once per
; run and reused: large blocks ask this for every master.
procedure(flReachSet(from)
    prog((below stack cv)
        unless(boundp('flReachTable) && tablep(flReachTable)
            flReachTable=makeTable('flReachTable nil)
        )

        below=flReachTable[from]
        when(below return(below))

        below=makeTable('flReachSet nil)
        stack=list(from)

        while(stack
            cv=car(stack)
            stack=cdr(stack)

            foreach(rec flChildList(cv)
                unless(below[cadr(rec)]
                    below[cadr(rec)]=t
                    stack=cons(cadr(rec) stack)
                )
            )
        )

        flReachTable[from]=below
        return(below)
    )
)

; True when master `target` is placed somewhere below master `from`.
procedure(flReaches(from target)
    prog((below)
        below=flReachSet(from)
        return(if(below[target] then t else nil))
    )
)

; Seconds since the search started.
procedure(flElapsed()
    if(boundp('flStartTime) && stringp(flStartTime) then
        compareTime(getCurrentTime() flStartTime)
    else
        0
    )
)

; Clock read on every 20th call only (cheap in tight loops).
procedure(flClock()
    prog(()
        flTimeTicks=flTimeTicks+1

        when(flTimeTicks==1 || zerop(mod(flTimeTicks 20))
            flLastElapsed=flElapsed()
        )

        return(flLastElapsed)
    )
)

; Time limit for the pin guide (S2L) and the schematic walk and trace
; (L2S). Stays t once reached; the marks found so far are kept.
procedure(flSoftTimeUp()
    prog(()
        when(flTimeStopped return(t))

        when(
            numberp(flTimeoutSeconds) &&
            flTimeoutSeconds>0 &&
            flClock()>=flTimeoutSeconds

            flTimeStopped=t
        )

        return(flTimeStopped)
    )
)

; Last resort for the whole search at twice the limit: the search fails
; and its new visuals are cleared.
procedure(flHardTimeCheck()
    when(
        numberp(flTimeoutSeconds) &&
        flTimeoutSeconds>0 &&
        flClock()>=2*flTimeoutSeconds

        flHardStopped=t
        error(sprintf(nil "Finder: search stopped after %d s." flLastElapsed))
    )
    t
)

; "3 s", or "<1 s".
procedure(flTimeText()
    prog((e)
        e=flElapsed()
        return(if(e<1 then "<1 s" else sprintf(nil "%d s" e)))
    )
)

; Return (scopes reason).
; CURRENT: the edit cell.
; BOTTOM: every layout master with the strongest endpoint instance-name
; label evidence. Cell names are not compared.
; A winner placed inside another winner is dropped: the outer block
; reaches it through its own instance-name labels (e.g. bus units).
; `evidence`: names used instead of the endpoint names (all instance names
; of a block schematic when the endpoints were reached through that block).
; True when master cv is a saved-cell layout or placed inside one.
procedure(flInsideSource(cv)
    prog((found)
        foreach(m flSourceMasters
            when(!found && or(m==cv flReaches(m cv))
                found=t
            )
        )
        return(found)
    )
)

procedure(flChooseScopes(root pairs @optional evidence)
    prog((names count best hits winners outer nested tbl src)
        unless(flBottomMode
            return(list(list(root) nil))
        )

        names=if(evidence then evidence else flIdentityNames(pairs))

        ; The layout of the schematic cell the names were saved in
        ; (crc_gen -> crc_gen), when it holds the endpoint labels. Auto
        ; names (I59, I210) of unrelated cells are then never used.
        unless(evidence
            foreach(m flSourceMasters
                when(flIdentityCount(m names)>0
                    src=cons(m src)
                )
            )

            when(src
                return(list(reverse(src) nil))
            )
        )

        count=length(names)
        best=0
        tbl=makeTable('flEvidence nil)

        foreach(n names
            tbl[n]=t
        )

        ; Saved cell found but its labels are in sub-cells: look only inside it.
        foreach(cv flMasters
            hits=if(
                or(
                    evidence
                    !flSourceMasters
                    flInsideSource(cv)
                )
            then
                flIdentityCountT(cv tbl)
            else
                0
            )

            cond(
                (hits>best
                    best=hits
                    winners=list(cv)
                )
                (hits>0 && hits==best
                    winners=cons(cv winners)
                )
            )
        )

        when(best==0
            return(list(
                nil
                "No layout block has any endpoint instance-name label"
            ))
        )

        when(best==1 && count>1 && length(winners)>1
            return(list(
                nil
                sprintf(nil
                    "Only 1 of %d endpoint instance names matched, in %d blocks"
                    count length(winners)
                )
            ))
        )

        winners=reverse(winners)

        foreach(cv winners
            nested=nil

            foreach(other winners
                when(!nested && other!=cv && flReaches(other cv)
                    nested=t
                )
            )

            unless(nested
                outer=cons(cv outer)
            )
        )

        return(list(
            if(outer then reverse(outer) else winners)
            nil
        ))
    )
)

; Short text such as "crc_gen, temp_crc_gen".
procedure(flCellListText(cvs)
    prog((text count)
        text=""
        count=0

        foreach(cv cvs
            when(count<4
                text=strcat(
                    text
                    if(count>0 then ", " else "")
                    cv~>cellName
                )
            )
            count=count+1
        )

        when(count>4
            text=strcat(text sprintf(nil ", +%d more" count-4))
        )

        return(text)
    )
)

; Mark labels named `innerName` in one occurrence (net label of the same
; signal under the block's own name). Return the number marked.
procedure(flMarkInnerLabels(occ innerName hs)
    prog((count)
        count=0

        foreach(label car(flLayoutIndex(car(occ)))
            when(label~>theLabel==innerName
                flMark(
                    hs
                    dbTransformPoint(label~>xy cadr(occ))
                    dbTransformBBox(label~>bBox cadr(occ))
                )
                count=count+1
            )
        )

        return(count)
    )
)

; ---- Placed objects: instances and mosaic elements ----
; A mosaic element is ('flElem master transform name cellName bBox).
; The name is "<mosaic>[row,col]", counted from the lower-left element.

procedure(flElemP(x)
    listp(x) && car(x)=='flElem
)

procedure(flObjMaster(x)
    if(flElemP(x) then
        nth(1 x)
    else
        car(errset(x~>master nil))
    )
)

procedure(flObjTransform(x)
    if(flElemP(x) then nth(2 x) else x~>transform)
)

procedure(flObjName(x)
    if(flElemP(x) then nth(3 x) else flName(x))
)

procedure(flObjBBox(x)
    if(flElemP(x) then
        nth(5 x)
    else
        car(errset(x~>bBox nil))
    )
)

procedure(flObjCell(x)
    if(flElemP(x) then
        nth(4 x)
    else
        car(errset(x~>cellName nil))
    )
)

; Bounding box of bb after transform tr, normalized.
procedure(flTransformBox(bb tr)
    prog((out p)
        foreach(corner
            list(
                car(bb)
                cadr(bb)
                list(caar(bb) cadadr(bb))
                list(caadr(bb) cadar(bb))
            )

            p=dbTransformPoint(corner tr)
            out=flUnion(out list(p p))
        )

        return(out)
    )
)

; Element of a simple mosaic whose area holds point p, or nil.
; Element areas are cut from the mosaic bounding box with the pitch, so
; the result does not depend on the sign of the pitch or on rotation.
; Where elements overlap, the element with the nearest center wins.
procedure(flMosaicElementAt(m p)
    prog((info master orient rows cols ux uy name r mb b0 w h
          row col bb c dx dy d best bestD tr)
        info=flMosaicInfo(m)
        unless(info return(nil))

        master=nth(0 info)
        orient=nth(2 info)
        rows=nth(3 info)
        cols=nth(4 info)
        ux=abs(nth(5 info))
        uy=abs(nth(6 info))
        name=nth(7 info)

        r=errset(m~>bBox nil)
        mb=if(r then car(r) else nil)
        unless(mb return(nil))

        r=errset(flTransformBox(master~>bBox list(0:0 orient 1.0)) nil)
        b0=if(r then car(r) else nil)
        unless(b0 return(nil))

        w=caadr(b0)-caar(b0)
        h=cadadr(b0)-cadar(b0)

        when(
            abs((caadr(mb)-caar(mb))-((cols-1)*ux+w))>0.01 ||
            abs((cadadr(mb)-cadar(mb))-((rows-1)*uy+h))>0.01

            return(nil)
        )

        row=0

        while(row<rows
            col=0

            while(col<cols
                bb=list(
                    list(caar(mb)+col*ux cadar(mb)+row*uy)
                    list(caar(mb)+col*ux+w cadar(mb)+row*uy+h)
                )

                when(flInside(p bb)
                    c=flCenter(bb)
                    dx=car(c)-car(p)
                    dy=cadr(c)-cadr(p)
                    d=dx*dx+dy*dy

                    when(!best || d<bestD
                        best=list(row col bb)
                        bestD=d
                    )
                )

                col=col+1
            )

            row=row+1
        )

        unless(best return(nil))

        bb=caddr(best)
        tr=list(
            list(caar(bb)-caar(b0) cadar(bb)-cadar(b0))
            orient
            1.0
        )

        return(list(
            'flElem
            master
            tr
            sprintf(nil "%s[%d,%d]" name car(best) cadr(best))
            master~>cellName
            bb
        ))
    )
)

; Placed object that holds point p: the instance itself, the mosaic
; element under p, or nil.
procedure(flHolder(inst p)
    prog((r type)
        r=errset(inst~>objType nil)
        type=if(r then car(r) else nil)

        unless(flInside(p inst~>bBox) return(nil))

        cond(
            (type=="inst" return(inst))
            (type=="mosaic"
                r=errset(flMosaicElementAt(inst p) nil)
                return(if(r then car(r) else nil))
            )
        )

        return(nil)
    )
)

; ---- Geometry terminals (option cells and resistor PCells) ----

; Value of a schematic property: instance property, symbol property, CDF.
procedure(flInstValue(inst pname)
    prog((r v props)
        r=errset(inst~>prop nil)
        props=if(r && listp(car(r)) then car(r) else nil)

        foreach(p props
            when(!v && p~>name==pname
                v=p~>value
            )
        )
        when(v return(v))

        r=errset(inst~>master~>prop nil)
        props=if(r && listp(car(r)) then car(r) else nil)

        foreach(p props
            when(!v && p~>name==pname
                v=p~>value
            )
        )
        when(v return(v))

        r=errset(
            get(cdfGetInstCDF(inst) stringToSymbol(pname))~>value
            nil
        )
        when(r && car(r) return(car(r)))

        return(nil)
    )
)

; "0.001" -> 0.001, "100M" -> 1e8, "1t" -> 1e12, "5K" -> 5000.0.
; M or meg is mega, m is milli. Returns nil when no number is found.
procedure(flParseOhm(v)
    prog((s n i num suffix first)
        when(numberp(v) return(v*1.0))
        unless(stringp(v) return(nil))

        s=v
        n=strlen(s)
        i=1

        while(i<=n &&
            member(
                substring(s i 1)
                list("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "." "+" "-")
            )
            i=i+1
        )

        when(i==1 return(nil))

        num=atof(substring(s 1 i-1))
        suffix=if(i<=n then substring(s i n-i+1) else "")
        first=if(strlen(suffix)>0 then substring(suffix 1 1) else "")

        cond(
            (suffix=="" return(num))
            (strlen(suffix)>=3 && lowerCase(substring(suffix 1 3))=="meg"
                return(num*1.0e6)
            )
            (first=="T" || first=="t" return(num*1.0e12))
            (first=="G" || first=="g" return(num*1.0e9))
            (first=="M" return(num*1.0e6))
            (first=="m" return(num*1.0e-3))
            (first=="K" || first=="k" return(num*1.0e3))
            (first=="u" return(num*1.0e-6))
            (first=="n" return(num*1.0e-9))
            (first=="p" return(num*1.0e-12))
            (first=="f" return(num*1.0e-15))
        )

        return(num)
    )
)

; Schematic instances behind the captured endpoints; read lazily.
procedure(flRememberInstance(inst instName)
    when(inst && stringp(instName)
        flSchInstances=cons(list(instName inst) flSchInstances)
    )
    t
)

; Schematic option state from the property r.
; Return (state raw ohm); state is 'on, 'off or nil. nil when unreadable.
procedure(flOptionStateOf(inst)
    prog((r raw ohm state)
        r=errset(flInstValue(inst flOptionProp) nil)
        raw=if(r then car(r) else nil)
        ohm=flParseOhm(raw)

        state=cond(
            (!ohm nil)
            (ohm<=flOptionOnMaxOhm 'on)
            (ohm>=flOptionOffMinOhm 'off)
            (t nil)
        )

        return(list(state raw ohm))
    )
)

; Layer names used directly in a master (no descent).
procedure(flShapeLayers(master)
    prog((r out)
        r=errset(master~>shapes nil)

        foreach(fig if(r then car(r) else nil)
            r=errset(fig~>layerName nil)

            when(r && stringp(car(r)) && !member(car(r) out)
                out=cons(car(r) out)
            )
        )

        return(out)
    )
)

; Two end points of a resistor PCell, in master coordinates.
; The two farthest end cells (cont mosaics); otherwise the ends of the
; resistor body shape.
procedure(flResistorEnds(master)
    prog((r centers best bestD d dx dy bb figBB w h cx cy)
        r=errset(master~>instances nil)

        foreach(inst if(r then car(r) else nil)
            when(member(inst~>cellName flResistorEndCells)
                centers=cons(flCenter(inst~>bBox) centers)
            )
        )

        when(length(centers)>=2
            bestD=-1.0

            foreach(a centers
                foreach(b centers
                    dx=car(a)-car(b)
                    dy=cadr(a)-cadr(b)
                    d=dx*dx+dy*dy

                    when(d>bestD
                        bestD=d
                        best=list(a b)
                    )
                )
            )

            return(best)
        )

        foreach(fig master~>shapes
            when(member(fig~>layerName flResistorLayers)
                figBB=fig~>bBox
                bb=flUnion(bb figBB)
            )
        )

        unless(bb return(nil))

        w=caadr(bb)-caar(bb)
        h=cadadr(bb)-cadar(bb)
        cx=(caar(bb)+caadr(bb))/2.0
        cy=(cadar(bb)+cadadr(bb))/2.0

        return(
            if(w>=h then
                list(list(caar(bb) cy) list(caadr(bb) cy))
            else
                list(list(cx cadar(bb)) list(cx cadadr(bb)))
            )
        )
    )
)

; Kind of a placed master, cached per run:
;   (option on)     marker layer found; on=t when the metal layer is present
;   (resistor ends) resistor body layer found
;   nil             ordinary cell (pin labels are used)
procedure(flMasterKind(master)
    prog((cached layers pair result isRes ends r)
        unless(flUseGeometryTerminals return(nil))

        cached=flKindTable[master]
        when(cached return(car(cached)))

        r=errset(length(master~>instances) nil)

        when(r && car(r)>flGeometryMaxInstances
            flKindTable[master]=list(nil)
            return(nil)
        )

        layers=flShapeLayers(master)

        foreach(p flOptionLayers
            when(!pair && member(car(p) layers)
                pair=p
            )
        )

        foreach(l flResistorLayers
            when(member(l layers) isRes=t)
        )

        cond(
            (pair
                result=list(
                    'option
                    if(member(cadr(pair) layers) then t else nil)
                    car(pair)
                    cadr(pair)
                )
            )
            (isRes
                ends=car(errset(flResistorEnds(master) nil))

                when(ends
                    result=list('resistor ends)
                )
            )
        )

        flKindTable[master]=list(result)
        return(result)
    )
)

; Terminal points of a geometry-terminal cell in the parent coordinates.
; Option: instance center. Resistor: both ends. Otherwise nil.
procedure(flSpecialPoints(inst)
    prog((master kind tr points)
        master=flObjMaster(inst)
        unless(master return(nil))

        kind=flMasterKind(master)
        unless(kind return(nil))

        tr=flObjTransform(inst)

        cond(
            ((car(kind)=='option)
                return(list(
                    dbTransformPoint(flCenter(master~>bBox) tr)
                ))
            )
            ((car(kind)=='resistor)
                foreach(p cadr(kind)
                    points=cons(dbTransformPoint(p tr) points)
                )
                return(reverse(points))
            )
        )

        return(nil)
    )
)

; Text for the REQUIRED line: "", " (option OFF)" or " (resistor ends)".
procedure(flSpecialTag(inst)
    prog((master kind)
        master=flObjMaster(inst)
        unless(master return(""))

        kind=flMasterKind(master)

        cond(
            (!kind return(""))
            ((car(kind)=='option)
                return(
                    if(cadr(kind) then " (option ON)" else " (option OFF)")
                )
            )
            (t return(" (resistor)"))
        )

        return("")
    )
)

; Layout option state against the schematic property r.
procedure(flCheckOption(inst instName)
    prog((r master kind rec info layoutOn schOn msg)
        master=flObjMaster(inst)
        unless(master return(nil))

        kind=flMasterKind(master)
        unless(kind && car(kind)=='option return(nil))

        layoutOn=cadr(kind)
        rec=assoc(instName flCurrentSchInsts || flSchInstances)
        r=if(rec then errset(flOptionStateOf(cadr(rec)) nil) else nil)
        info=if(r then car(r) else nil)

        unless(info && car(info)
            flNote(sprintf(nil
                "[OPTION] Schematic ON/OFF unknown for %L (property %s=%L); layout is %s"
                instName flOptionProp
                if(info then cadr(info) else nil)
                if(layoutOn then "ON" else "OFF")
            ) t)
            return(nil)
        )

        schOn=(car(info)=='on)

        when(schOn!=layoutOn
            msg=sprintf(nil
                "[OPTION] %s: option mismatch - schematic %s (%s=%L), layout %s (%s %s)"
                instName
                if(schOn then "ON" else "OFF")
                flOptionProp cadr(info)
                if(layoutOn then "ON" else "OFF")
                master~>cellName
                if(layoutOn then strcat("has " nth(3 kind)) else strcat("no " nth(3 kind)))
            )

            unless(member(msg flWarnings)
                flAlert(msg)
            )
        )

        return(t)
    )
)

; Read terminal labels only one level inside the placed PCell/SCell.
procedure(flTerminalPoints(inst pinName)
    prog((points p master tr)
        master=flObjMaster(inst)
        unless(master return(nil))
        tr=flObjTransform(inst)

        foreach(fig master~>shapes
            when(
                fig~>objType=="label" &&
                fig~>theLabel==pinName &&
                member(fig~>layerName flTerminalLabelLayers)

                p=dbTransformPoint(
                    fig~>xy tr
                )

                unless(member(p points)
                    points=cons(p points)
                )
            )
        )

        return(reverse(points))
    )
)

; Points of the other terminal of a swappable pair (MOS D/S) on a PCell
; instance, in the parent coordinates; nil when not applicable.
procedure(flSwapPoints(inst pinName)
    prog((master other)
        unless(flSwapPins && stringp(pinName) return(nil))

        master=flObjMaster(inst)
        unless(flPCellP(master) return(nil))

        foreach(pair flSwapPins
            when(!other && member(pinName pair)
                foreach(x pair
                    when(!other && x!=pinName
                        other=x
                    )
                )
            )
        )

        unless(other return(nil))
        return(flTerminalPoints(inst other))
    )
)

; Pin name of the swap partner, for messages ("S" for "D").
procedure(flSwapName(pinName)
    prog((other)
        foreach(pair flSwapPins
            when(!other && member(pinName pair)
                foreach(x pair
                    when(!other && x!=pinName
                        other=x
                    )
                )
            )
        )

        return(other)
    )
)

; "I25<7>" -> "I25". Names without an index are returned unchanged.
procedure(flNameBase(name)
    prog((tail)
        unless(stringp(name) return(nil))
        tail=rindex(name "<")

        if(tail && strlen(tail)<strlen(name) then
            return(substring(name 1 strlen(name)-strlen(tail)))
        else
            return(name)
        )
    )
)

; Instances identified by instance-name labels in cv.
; Evidence order: attached label > label inside exactly one instance
; > label inside overlapping instances.
procedure(flLabelCandidates(cv labels)
    prog((instances r parent hits attached uniqueHits multiHits elem)
        instances=cv~>instances

        foreach(label labels
            r=errset(label~>parent nil)
            parent=if(r then car(r) else nil)

            if(
                parent &&
                parent~>objType=="inst" &&
                member(parent instances)
            then
                unless(member(parent attached)
                    attached=cons(parent attached)
                )
            else
                hits=nil

                foreach(inst instances
                    elem=flHolder(inst label~>xy)

                    when(elem
                        hits=cons(elem hits)
                    )
                )

                cond(
                    (length(hits)==1
                        unless(member(car(hits) uniqueHits)
                            uniqueHits=cons(car(hits) uniqueHits)
                        )
                    )
                    (hits
                        foreach(inst hits
                            unless(member(inst multiHits)
                                multiHits=cons(inst multiHits)
                            )
                        )
                    )
                )
            )
        )

        return(reverse(attached || uniqueHits || multiHits))
    )
)

; Every instance that holds one of the labels: attached parent or an
; instance whose bounding box contains the label origin.
procedure(flLabelAllHits(cv labels)
    prog((r parent out elem)
        foreach(label labels
            r=errset(label~>parent nil)
            parent=if(r then car(r) else nil)

            when(
                parent &&
                parent~>objType=="inst" &&
                !member(parent out)

                out=cons(parent out)
            )

            foreach(inst cv~>instances
                elem=flHolder(inst label~>xy)

                when(elem && !member(elem out)
                    out=cons(elem out)
                )
            )
        )

        return(reverse(out))
    )
)

; Leaf instance inside a block master that plays the role of `name`.
; Exact instance-name labels first, then labels with the same base name
; ("I25<0>" inside a bus unit placed for "I25<7>"). Several matches that
; all carry the pin are left unresolved instead of guessed.
procedure(flResolveInside(master name pinName depth)
    prog((key cached labels base candidates withPin result)
        key=list(master name pinName depth)
        cached=assoc(key flInsideCache)
        when(cached return(cadr(cached)))

        foreach(label cadr(flLayoutIndex(master))
            when(label~>theLabel==name
                labels=cons(label labels)
            )
        )

        unless(labels
            base=flNameBase(name)

            foreach(label cadr(flLayoutIndex(master))
                when(flNameBase(label~>theLabel)==base
                    labels=cons(label labels)
                )
            )
        )

        candidates=flLabelCandidates(master labels)

        cond(
            (length(candidates)==1
                result=car(candidates)
            )
            (candidates
                foreach(inst candidates
                    when(flPinPoints(inst name pinName depth)
                        withPin=cons(inst withPin)
                    )
                )

                when(length(withPin)==1
                    result=car(withPin)
                )
            )
        )

        flInsideCache=cons(
            list(key result)
            flInsideCache
        )

        return(result)
    )
)

; Terminal-label points of inst, in the coordinates of inst's parent.
; Pin labels are read only from the immediate master of the identified
; instance. When that master is a block (unit) without the pin label,
; descend through its instance-name labels to the leaf instance.
; MOS PCells carry no instance-name labels, so internal S/D are never used.
procedure(flPinPoints(inst name pinName depth)
    prog((points master inner tr q special)
        special=flSpecialPoints(inst)
        when(special return(special))

        points=flTerminalPoints(inst pinName)

        when(points || depth>=flPinDescendLimit
            return(points)
        )

        master=flObjMaster(inst)
        unless(master return(nil))

        inner=flResolveInside(master name pinName depth+1)
        unless(inner return(nil))

        tr=flObjTransform(inst)

        foreach(p flPinPoints(inner name pinName depth+1)
            q=dbTransformPoint(p tr)

            unless(member(q points)
                points=cons(q points)
            )
        )

        return(reverse(points))
    )
)

; Return (status instances).
;   'ok          one layout instance
;   'pinFiltered several name labels; only one instance has the pin
;   'candidate   several instances have the pin
;   'nopin       several instances; none has the pin
;   'unresolved  name label is not inside any instance
;   'missing     no instance-name label
; Overlapping bounding boxes (fillers, wells) resolved by the pin are 'ok.
; Missing identity does not prove missing geometry.
procedure(flResolveInstance(cv name pinName)
    prog((key cached labels candidates withPin result wide)
        key=list(cv name pinName)
        cached=assoc(key flResolveCache)
        when(cached return(cadr(cached)))

        foreach(label cadr(flLayoutIndex(cv))
            when(label~>theLabel==name
                labels=cons(label labels)
            )
        )

        candidates=flLabelCandidates(cv labels)

        cond(
            (!labels
                result=list('missing nil)
            )
            (!candidates
                result=list('unresolved nil)
            )
            (length(candidates)==1
                result=list('ok candidates)
            )
            (t
                foreach(inst candidates
                    when(flPinPoints(inst name pinName 0)
                        withPin=cons(inst withPin)
                    )
                )

                withPin=reverse(withPin)

                cond(
                    (length(withPin)==1
                        result=list(
                            if(length(labels)>1 then 'pinFiltered else 'ok)
                            withPin
                        )
                    )
                    (withPin
                        result=list('candidate withPin)
                    )
                    (t
                        result=list('nopin candidates)
                    )
                )
            )
        )

        ; The chosen instance has no pin (e.g. a guard ring around the
        ; resistor): retry with every instance that holds the label.
        when(
            (car(result)=='ok && !flPinPoints(car(cadr(result)) name pinName 0)) ||
            car(result)=='nopin

            wide=flLabelAllHits(cv labels)
            withPin=nil

            foreach(inst wide
                when(flPinPoints(inst name pinName 0)
                    withPin=cons(inst withPin)
                )
            )

            withPin=reverse(withPin)

            cond(
                (length(withPin)==1
                    result=list('ok withPin)
                )
                (withPin
                    result=list('candidate withPin)
                )
                (length(wide)>length(cadr(result))
                    result=list('nopin wide)
                )
            )
        )

        flResolveCache=cons(
            list(key result)
            flResolveCache
        )

        return(result)
    )
)

; Short text such as "I12(nand2_0p18), I15(zinvs1)".
procedure(flInstanceListText(insts)
    prog((text count)
        text=""
        count=0

        foreach(inst insts
            when(count<4
                text=strcat(
                    text
                    if(count>0 then ", " else "")
                    sprintf(nil "%s(%s)"
                        flObjName(inst) || "?"
                        flObjCell(inst) || "?"
                    )
                )
            )
            count=count+1
        )

        when(count>4
            text=strcat(text sprintf(nil ", +%d more" count-4))
        )

        return(text)
    )
)

; Mark every instance-name label `instName` of one occurrence.
procedure(flMarkNameLabels(occ instName hs)
    prog((count)
        count=0

        foreach(label cadr(flLayoutIndex(car(occ)))
            when(label~>theLabel==instName
                flMark(
                    hs
                    dbTransformPoint(label~>xy cadr(occ))
                    dbTransformBBox(label~>bBox cadr(occ))
                )
                count=count+1
            )
        )

        flLabelOnlyMarks=flLabelOnlyMarks+count
        return(count)
    )
)

; Points to mark for one resolved instance, in occurrence-master coordinates.
; Option/resistor (symmetric use): its instance-name label(s) only.
; Other cells: the pin positions.
procedure(flRequiredPoints(occ inst instName pinName)
    prog((master all own bb)
        master=flObjMaster(inst)

        unless(master && flMasterKind(master)
            return(flPinPoints(inst instName pinName 0))
        )

        bb=flObjBBox(inst)

        foreach(label cadr(flLayoutIndex(car(occ)))
            when(label~>theLabel==instName
                all=cons(label~>xy all)

                when(bb && flInside(label~>xy bb)
                    own=cons(label~>xy own)
                )
            )
        )

        return(reverse(own || all))
    )
)

; True when every placed object in insts (inside the occurrence at path)
; lies in a block where the net label was found (flLabelPaths).
procedure(flInLabelBlocks(path insts)
    prog((all)
        unless(flLabelPaths return(nil))
        all=t

        foreach(inst insts
            when(all
                unless(
                    stringp(flObjName(inst)) &&
                    flUnderLabel(flJoin(path flObjName(inst)) flLabelPaths)

                    all=nil
                )
            )
        )

        return(all)
    )
)

; True when one of the layout objects is a placed block for schematic
; cell `cell`: not a PCell, cell name equal to it or a name variant.
; A gate drawn flat (lvn/lvp PCells under the label) is not a block.
procedure(flPlacedBlockP(cell layInsts)
    prog((found master)
        foreach(x layInsts
            master=flObjMaster(x)

            when(
                !found &&
                master &&
                !flPCellP(master) &&
                car(flCellNameMatch(cell list(master) t))

                found=t
            )
        )

        return(found)
    )
)

; CURRENT: the pin of a block endpoint (e.g. Icrc_gen) is not in the edit
; cell. Its instance-name label is not marked; a note points to
; CURRENT TO BOTTOM. Return t when the endpoint is skipped.
; layInsts: layout objects found for the label. When none of them is a
; placed block (gate drawn flat), the endpoint is not skipped.
procedure(flBlockSkip(name path instName pinName @optional (layInsts 'none))
    prog((rec inst)
        when(flBottomMode return(nil))

        rec=assoc(instName flCurrentSchInsts || flSchInstances)
        inst=if(rec then cadr(rec) else nil)

        unless(
            inst &&
            car(errset(flBlockCellP(inst~>libName inst~>cellName) nil))

            return(nil)
        )

        unless(layInsts=='none
            unless(flPlacedBlockP(inst~>cellName layInsts)
                return(nil)
            )
        )

        flBlockSkips=flBlockSkips+1

        unless(member(inst~>cellName flSkipNames)
            flSkipNames=append(flSkipNames list(inst~>cellName))
        )

        flNote(sprintf(nil
            "[PIN-FIND] SKIP net=%L %s pin=%L: inside block %s; not in this cell, use CURRENT TO BOTTOM"
            name flJoin(path instName) pinName inst~>cellName
        ) t)

        return(t)
    )
)

; Schematic cell name of endpoint instance instName, or nil.
procedure(flSchCellOf(instName)
    prog((rec)
        rec=assoc(instName flCurrentSchInsts || flSchInstances)
        unless(rec return(nil))
        return(car(errset(cadr(rec)~>cellName nil)))
    )
)

; Endpoint with no instance-name label: when exactly one layout instance
; of its schematic cell (same name, or a name variant for blocks) is
; directly inside the occurrence and it has the pin label, the pin gets the
; donut. No box otherwise (it only clutters large blocks).
; Return t when the pin was marked.
procedure(flMarkPinByCell(occ name instName pinName hs)
    prog((rec schInst cell master masters match insts points point swap)
        rec=assoc(instName flCurrentSchInsts || flSchInstances)
        schInst=if(rec then cadr(rec) else nil)
        unless(schInst return(nil))

        cell=car(errset(schInst~>cellName nil))
        unless(stringp(cell) return(nil))

        foreach(inst car(occ)~>instances
            when(inst~>objType=="inst"
                master=car(errset(inst~>master nil))

                when(master && !member(master masters)
                    masters=cons(master masters)
                )
            )
        )

        match=flCellNameMatch(
            cell
            masters
            car(errset(flBlockCellP(schInst~>libName cell) nil))
        )
        unless(car(match) return(nil))

        foreach(inst car(occ)~>instances
            when(
                inst~>objType=="inst" &&
                member(car(errset(inst~>master nil)) car(match))

                insts=cons(inst insts)
            )
        )

        unless(length(insts)==1 return(nil))

        points=flTerminalPoints(car(insts) pinName)
        unless(points return(nil))

        swap=flSwapPoints(car(insts) pinName)

        if(swap then
            foreach(p append(points swap)
                point=dbTransformPoint(p cadr(occ))
                flMarkCandidate(hs point)
                flCandidateMarks=flCandidateMarks+1
            )

            flCandidatePins=flCandidatePins+1

            flNote(sprintf(nil
                "[S2L] %s: %s has no instance-name label%s - %s and %s boxed on %s (by cell name; S/D may be swapped)"
                name instName flWhere(caddr(occ)) pinName flSwapName(pinName)
                car(insts)~>cellName
            ))
        else
            foreach(p points
                point=dbTransformPoint(p cadr(occ))
                flMark(hs point list(point point))
                flPinMarks=flPinMarks+1
            )

            flFoundPins=flFoundPins+1

            flNote(sprintf(nil
                "[S2L] %s: %s has no instance-name label%s - pin %s marked on %s (by cell name)"
                name instName flWhere(caddr(occ)) pinName car(insts)~>cellName
            ))
        )

        return(t)
    )
)

; Warning text for an endpoint whose pin position is unknown.
procedure(flNoPinText(name pinName instName path)
    prog((cell)
        cell=flSchCellOf(instName)

        return(sprintf(nil
            "[S2L] %s: pin %s of %s%s not found%s (no pin label) - instance label marked"
            name pinName instName
            if(stringp(cell) then sprintf(nil " (%s)" cell) else "")
            flWhere(path)
        ))
    )
)

procedure(flMarkRequiredPins(occ name pairs hs)
    prog((transform path resolved status insts points point
          instName pinName cellName message swap)

        transform=cadr(occ)
        path=caddr(occ)

        foreach(pair pairs
            instName=car(pair)
            pinName=cadr(pair)
            flExpectedPins=flExpectedPins+1

            resolved=flResolveInstance(car(occ) instName pinName)
            status=car(resolved)
            insts=cadr(resolved)

            ; The endpoint block holds the net label itself: that label is
            ; the mark, its terminal is not marked.
            when(insts && flInLabelBlocks(path insts)
                status='labeled
            )

            cond(
                (status=='labeled
                    flFoundPins=flFoundPins+1

                    flDetail(sprintf(nil
                        "[PIN-FIND] LABELED BLOCK net=%L path=%s instance=%L pin=%L; net label marked instead"
                        name path instName pinName
                    ))
                )

                (status=='missing
                    ; No name label: its pin by cell name if certain; else
                    ; CIW only (popup only when nothing was marked).
                    unless(flMarkPinByCell(occ name instName pinName hs)
                        flMissingIdentity=flMissingIdentity+1
                        cellName=flSchCellOf(instName)

                        message=sprintf(nil
                            "[S2L] %s: %s%s has no instance-name label%s - not marked"
                            name
                            instName
                            if(stringp(cellName) then
                                sprintf(nil " (%s)" cellName)
                            else
                                ""
                            )
                            flWhere(path)
                        )

                        unless(member(message flWarnings)
                            flSoftAlert(message)
                        )
                    )
                )

                (status=='ok || status=='pinFiltered
                    points=flRequiredPoints(occ car(insts) instName pinName)
                    swap=if(points then flSwapPoints(car(insts) pinName) else nil)

                    cond(
                        (swap
                            ; MOS S/D may be swapped in layout: box both.
                            foreach(p append(points swap)
                                point=dbTransformPoint(p transform)
                                flMarkCandidate(hs point)
                                flCandidateMarks=flCandidateMarks+1
                            )

                            flCandidatePins=flCandidatePins+1

                            flNote(sprintf(nil
                                "[S2L] %s: %s pin %s%s - %s and %s boxed (S/D may be swapped, check which)"
                                name instName pinName flWhere(path)
                                pinName flSwapName(pinName)
                            ))
                        )
                        (points
                            foreach(p points
                                point=dbTransformPoint(p transform)
                                flMark(hs point list(point point))
                                flPinMarks=flPinMarks+1
                            )

                            flFoundPins=flFoundPins+1

                            flDetail(sprintf(nil
                                "[PIN-FIND] REQUIRED net=%L path=%s instance=%L pin=%L%s"
                                name path instName pinName
                                flSpecialTag(car(insts))
                            ))

                            flCheckOption(car(insts) instName)

                            when(status=='pinFiltered
                                flWarn(sprintf(nil
                                    "[S2L] %s: duplicate label %s%s - marked %s (has pin %s)"
                                    name instName flWhere(path)
                                    flInstanceListText(insts) pinName
                                ))
                            )
                        )
                        (t
                            unless(flBlockSkip(name path instName pinName insts)
                                flMissingPins=flMissingPins+1
                                flMarkNameLabels(occ instName hs)
                                flWarn(flNoPinText(name pinName instName path))
                            )
                        )
                    )
                )

                (status=='candidate
                    foreach(inst insts
                        foreach(p append(
                                flRequiredPoints(occ inst instName pinName)
                                flSwapPoints(inst pinName)
                            )
                            point=dbTransformPoint(p transform)
                            flMarkCandidate(hs point)
                            flCandidateMarks=flCandidateMarks+1
                        )
                    )

                    flCandidatePins=flCandidatePins+1

                    flWarn(sprintf(nil
                        "[S2L] %s: %s on %d instances%s (%s) - all boxed, check which"
                        name instName
                        length(insts)
                        flWhere(path)
                        flInstanceListText(insts)
                    ))
                )

                (status=='nopin
                    unless(flBlockSkip(name path instName pinName insts)
                        flAmbiguousPins=flAmbiguousPins+1
                        flMarkNameLabels(occ instName hs)
                        flWarn(flNoPinText(name pinName instName path))
                    )
                )

                (t
                    unless(flBlockSkip(name path instName pinName nil)
                        flAmbiguousPins=flAmbiguousPins+1
                        flMarkNameLabels(occ instName hs)

                        flWarn(sprintf(nil
                            "[S2L] %s: label %s is not on any instance%s - name label marked"
                            name instName flWhere(path)
                        ))
                    )
                )
            )
        )

        return(t)
    )
)

; ---- Schematic descent below unlabeled block endpoints (BOTTOM) ----

; True when `name` is an instance-name label in any collected layout master.
procedure(flLabelKnown(name)
    unless(flKnownLabels
        flKnownLabels=makeTable('flKnownLabels nil)

        foreach(cv flMasters
            foreach(label cadr(flLayoutIndex(cv))
                flKnownLabels[label~>theLabel]=t
            )
        )
    )

    flKnownLabels[name]
)

; Signal inside a block schematic behind terminal `pinName`.
procedure(flTermSignal(child pinName)
    prog((r name)
        r=errset(dbFindSigByName(child pinName) nil)
        when(r && car(r) return(pinName))

        foreach(term child~>terminals
            when(!name && term~>name==pinName
                r=errset(term~>net~>name nil)
                when(r && stringp(car(r)) name=car(r))
            )
        )

        return(name)
    )
)

; (instName schematicInstance) for the endpoint names of one schematic.
procedure(flSchInstMap(cv pairs)
    prog((out)
        foreach(pair pairs
            unless(assoc(car(pair) out)
                foreach(inst cv~>instances
                    when(
                        !assoc(car(pair) out) &&
                        flContains(inst~>name car(pair))

                        out=cons(list(car(pair) inst) out)
                    )
                )
            )
        )

        return(out)
    )
)

; Every instance name of a schematic (pins excluded): block fingerprint.
procedure(flSchInstNames(cv)
    prog((out)
        foreach(inst cv~>instances
            unless(
                flPinSymbolP(inst) ||
                car(errset(inst~>libName nil))=="basic"

                foreach(n flExpand(inst~>name) || list(inst~>name)
                    out=cons(n out)
                )
            )
        )

        return(out)
    )
)

; Layout master cv may hold a block reached below parentScopes.
; CURRENT: only the edit cell itself.
; BOTTOM: anywhere for the first level ('top), else strictly inside a
; parent block.
procedure(flMatchAllowed(cv parentScopes)
    prog((ok)
        unless(flBottomMode return(cv==flRootCV))
        when(parentScopes=='top return(t))

        foreach(p parentScopes
            when(!ok && p!=cv && flReaches(p cv)
                ok=t
            )
        )

        return(ok)
    )
)

; Layout masters (from `masters`) named like schematic cell `cell`.
; Return (masters kind): kind "name" (same name) or "variant"
; (crc_gen_xxx / xxx_crc_gen, outermost ones only). Variants are tried only
; when `variants` is t (block cells) and no master has the same name.
procedure(flCellNameMatch(cell masters variants)
    prog((exact vars outer nested n cn)
        unless(stringp(cell) return(list(nil nil)))

        foreach(m masters
            when(m~>cellName==cell
                exact=cons(m exact)
            )
        )

        when(exact return(list(reverse(exact) "name")))
        unless(variants return(list(nil nil)))

        n=strlen(cell)

        foreach(m masters
            cn=m~>cellName

            when(
                and(
                    stringp(cn)
                    strlen(cn)>n+1
                    or(
                        substring(cn 1 n+1)==strcat(cell "_")
                        substring(cn strlen(cn)-n n+1)==strcat("_" cell)
                    )
                )

                vars=cons(m vars)
            )
        )

        ; A variant placed inside another variant is a part of it
        ; (crc_gen_u01 inside temp_crc_gen): keep the outer ones.
        foreach(m vars
            nested=nil

            foreach(o vars
                when(!nested && o!=m && flReaches(o m)
                    nested=t
                )
            )

            unless(nested
                outer=cons(m outer)
            )
        )

        when(outer return(list(outer "variant")))
        return(list(nil nil))
    )
)

; Note when a name variant stands for the schematic cell; printed in the
; CIW only when several variants are used.
procedure(flVariantNote(cell match)
    when(cadr(match)=="variant"
        flNote(
            sprintf(nil
                "[S2L] %s: layout %s used (name variant)%s"
                cell
                flCellListText(car(match))
                if(length(car(match))>1 then " - all used" else "")
            )
            length(car(match))<2
        )
    )
    t
)

; Layout masters that correspond to block schematic `child`.
; Return (scopes match): match is "name", "variant" (crc_gen_xxx,
; xxx_crc_gen) or the label share (0..1). Cached per block and parent.
procedure(flMatchBlocks(child parentScopes)
    prog((cached result)
        unless(boundp('flMatchCache) && tablep(flMatchCache)
            flMatchCache=makeTable('flMatchCache nil)
        )

        cached=assoc(parentScopes flMatchCache[child])
        when(cached return(cadr(cached)))

        result=flMatchBlocksNow(child parentScopes)
        flMatchCache[child]=cons(list(parentScopes result) flMatchCache[child])
        return(result)
    )
)

procedure(flMatchBlocksNow(child parentScopes)
    prog((allowed byName names e tbl best winners score)
        foreach(cv flMasters
            when(flMatchAllowed(cv parentScopes)
                allowed=cons(cv allowed)
            )
        )

        allowed=reverse(allowed)

        when(flUseCellNameMatch
            byName=flCellNameMatch(
                child~>cellName
                allowed
                car(errset(flBlockCellP(child~>libName child~>cellName) nil))
            )

            when(car(byName)
                flVariantNote(child~>cellName byName)
                return(byName)
            )
        )

        names=flSchInstNames(child)
        e=length(names)
        best=0.0

        unless(e>0 return(list(nil 0.0)))

        tbl=makeTable('flFingerprint nil)

        foreach(n names
            tbl[n]=t
        )

        foreach(cv allowed
            score=flIdentityCountT(cv tbl)*1.0/e

            cond(
                (score>best+1.0e-9
                    best=score
                    winners=list(cv)
                )
                (score>0.0 && abs(score-best)<=1.0e-9
                    winners=cons(cv winners)
                )
            )
        )

        return(list(
            if(best>=flBlockMatchMin then reverse(winners) else nil)
            best
        ))
    )
)

; True when some endpoint of the groups has its instance-name label in
; that group's layout cells.
procedure(flGroupsFound(groups)
    prog((found)
        foreach(g groups
            when(!found && listp(nth(3 g))
                foreach(scope nth(3 g)
                    when(
                        !found &&
                        flIdentityCount(scope flIdentityNames(cadr(g)))>0

                        found=t
                    )
                )
            )
        )

        return(found)
    )
)

; True when layout path `p` is `h` itself or lies below it.
procedure(flUnderPath(p h)
    prog((n)
        unless(stringp(p) && stringp(h)
            return(nil)
        )

        when(p==h || h=="/" || h==""
            return(t)
        )

        n=strlen(h)+1

        when(strlen(p)>n
            return(substring(p 1 n)==strcat(h "/"))
        )

        return(nil)
    )
)

; True when layout path `p` lies at or below one of the block paths in
; `paths` where the net label was found.
procedure(flUnderLabel(p paths)
    prog((found)
        foreach(h paths
            when(!found && flUnderPath(p h)
                found=t
            )
        )
        return(found)
    )
)

procedure(flMatchText(m)
    if(numberp(m) then sprintf(nil "%.2f" m) else sprintf(nil "%s" m))
)

; Layout match of block schematic `child`; a labeled block needs its
; layout by cell name ("name", or "variant" at the saved level).
procedure(flBlockMatch(child scopes labeled depth)
    prog((match)
        match=flMatchBlocks(child scopes)

        when(
            and(
                labeled
                !or(
                    equal(cadr(match) "name")
                    and(
                        equal(cadr(match) "variant")
                        depth==0
                    )
                )
            )

            match=list(nil cadr(match))
        )

        return(match)
    )
)

; Split endpoints into groups (path pairs instMap scopes match).
; scopes: 'top for the captured level (blocks chosen later from the
; endpoint labels), or the layout masters of this block schematic.
; An endpoint whose instance has no label in the layout is followed into
; its schematic; that block is used only when its layout is found.
; A block endpoint at the saved level (crc_gen, crc_reg) is followed
; whether or not its instance-name label is in the layout: block labels
; are not used. Labeled ones need their layout by cell name ("name" or
; "suffix"); labeled cells deeper down stay as before (standard cells).
procedure(flExpandGroups(netName schCv pairs instMap path depth scopes score
                        @optional innerName)
    prog((keep groups rec inst r child sigName info subPairs sub match
          labeled follow memoKey memo blk dup)
        foreach(pair pairs
            ; Time limit: stop here; the caller drops the pin guide.
            when(flSoftTimeUp() return(groups))

            sub=nil
            child=nil
            labeled=nil
            follow=nil
            dup=nil

            when(depth<flSchDescendLimit
                rec=assoc(car(pair) instMap)
                inst=if(rec then cadr(rec) else nil)
                labeled=flLabelKnown(car(pair))

                ; Labeled: only a block at the saved level (depth 0).
                follow=or(
                    !labeled
                    and(
                        depth==0
                        inst
                        car(errset(flBlockCellP(inst~>libName inst~>cellName) nil))
                    )
                )
            )

            when(follow
                r=if(inst then errset(flChildSchematic(inst) nil) else nil)
                child=if(r then car(r) else nil)

                when(child==schCv child=nil)

                when(child
                    ; Same block and pin from the same parent layout already
                    ; done on another path of this target: 'found (marked
                    ; once, at every placement), 'none (endpoint kept here)
                    ; or 'skip (block not in this layout).
                    memoKey=list(cadr(pair) scopes depth labeled)
                    memo=cadr(assoc(memoKey flGroupMemo[child]))
                    blk=child
                    match=nil

                    cond(
                        (memo=='found
                            dup=t
                        )
                        (memo=='none
                            child=nil
                        )
                        (memo=='skip
                            match=flBlockMatch(child scopes labeled depth)
                        )
                        (t
                            sigName=flTermSignal(child cadr(pair))
                            subPairs=nil

                            when(sigName
                                info=flEndpointInfo(child sigName nil)
                                subPairs=car(info)
                            )

                            if(!subPairs then
                                child=nil
                            else
                                match=flBlockMatch(child scopes labeled depth)

                                when(car(match)
                                    sub=flExpandGroups(
                                        netName
                                        child
                                        subPairs
                                        flSchInstMap(child subPairs)
                                        flJoin(path car(pair))
                                        depth+1
                                        car(match)
                                        cadr(match)
                                        sigName
                                    )

                                    ; Layout found but none of its endpoints
                                    ; is labeled there (e.g. a standard
                                    ; cell): keep the endpoint.
                                    unless(flGroupsFound(sub)
                                        sub=nil
                                        child=nil
                                    )
                                )
                            )

                            unless(flTimeStopped
                                flGroupMemo[blk]=cons(
                                    list(
                                        memoKey
                                        cond(
                                            (sub 'found)
                                            (child 'skip)
                                            (t 'none)
                                        )
                                    )
                                    flGroupMemo[blk]
                                )
                            )
                        )
                    )

                    ; Labeled block not followed in BOTTOM: keep it at this
                    ; level as before. CURRENT: skipped (not in this cell).
                    when(!sub && child && !dup && labeled && flBottomMode
                        child=nil
                    )

                    when(!sub && child && !dup && !flBottomMode &&
                         car(errset(flBlockCellP(child~>libName child~>cellName) nil))
                        flBlockSkips=flBlockSkips+1
                    )

                    cond(
                        (sub
                            flDetail(sprintf(nil
                                "[PIN-FIND] DESCEND net=%L %s pin=%L -> %s net=%L endpoints=%d match=%s"
                                netName
                                flJoin(path car(pair))
                                cadr(pair)
                                child~>cellName
                                sigName
                                length(subPairs)
                                flMatchText(cadr(match))
                            ))
                        )
                        (child && !dup
                            unless(member(child~>cellName flSkipNames)
                                flSkipNames=append(flSkipNames list(child~>cellName))
                            )

                            flNote(sprintf(nil
                                if(flBottomMode then
                                    "[PIN-FIND] SKIP net=%L %s pin=%L: block %s is not in this layout (best label match %s)"
                                else
                                    "[PIN-FIND] SKIP net=%L %s pin=%L: block %s is not the edit cell; use CURRENT TO BOTTOM (best label match %s)"
                                )
                                netName
                                flJoin(path car(pair))
                                cadr(pair)
                                child~>cellName
                                flMatchText(cadr(match))
                            ) t)
                        )
                    )
                )
            )

            cond(
                (sub
                    groups=append(groups sub)
                )
                (child
                    nil
                )
                (t
                    keep=cons(pair keep)
                )
            )
        )

        when(keep
            groups=cons(
                list(path reverse(keep) instMap scopes score innerName)
                groups
            )
        )

        return(groups)
    )
)

procedure(flViaText(path score)
    cond(
        (path=="/" || path=="" "")
        (score sprintf(nil " via=%s match=%s" path flMatchText(score)))
        (t sprintf(nil " via=%s" path))
    )
)

; True when a chosen block lies below the edit cell.
procedure(flSubScopeP(cv)
    prog((found)
        foreach(scope flScopeSet
            when(scope!=cv found=t)
        )
        return(found)
    )
)

; Layout masters that may be the cell of an instance target.
; cellInfo is (cellName isBlock). Same cell name first; for a block also
; "<cell>_<suffix>" (crc_gen -> crc_gen_temp).
procedure(flCellMatches(cellInfo)
    prog((match)
        match=flCellNameMatch(car(cellInfo) flMasters cadr(cellInfo))
        flVariantNote(car(cellInfo) match)
        return(car(match))
    )
)

; Placement mark: the instance outline with an X, plus the guide line.
; bb is in edit-cell coordinates.
procedure(flMarkBox(hs bb)
    prog((b x1 y1 x2 y2 origin)
        b=flDisplayBBox(bb)
        unless(b return(nil))

        x1=caar(b)
        y1=cadar(b)
        x2=caadr(b)
        y2=cadadr(b)
        origin=flDisplayPoint(0:0)

        geAddHilightLine(hs list(list(x1 y1) list(x2 y1)))
        geAddHilightLine(hs list(list(x2 y1) list(x2 y2)))
        geAddHilightLine(hs list(list(x2 y2) list(x1 y2)))
        geAddHilightLine(hs list(list(x1 y2) list(x1 y1)))
        geAddHilightLine(hs list(list(x1 y1) list(x2 y2)))
        geAddHilightLine(hs list(list(x1 y2) list(x2 y1)))
        geAddHilightLine(hs list(origin flCenter(b)))

        flResultBBox=flUnion(flResultBBox b)
        flMatches=flMatches+1
        return(t)
    )
)

; Box + X drawn once per search for the same area (bits of one iterated
; instance share the same blocks). Returns t when the area is marked.
procedure(flMarkBoxOnce(hs bb)
    prog((key)
        unless(boundp('flBoxSeen) && tablep(flBoxSeen)
            flBoxSeen=makeTable('flBoxSeen nil)
        )

        key=sprintf(nil "%L" bb)
        when(flBoxSeen[key] return(t))

        when(flMarkBox(hs bb)
            flBoxSeen[key]=t
            return(t)
        )

        return(nil)
    )
)

; Plain box (no X, no guide line), e.g. one mosaic element.
; bb is in edit-cell coordinates.
procedure(flMarkRect(hs bb)
    prog((b x1 y1 x2 y2)
        b=flDisplayBBox(bb)
        unless(b return(nil))

        x1=caar(b)
        y1=cadar(b)
        x2=caadr(b)
        y2=cadadr(b)

        geAddHilightLine(hs list(list(x1 y1) list(x2 y1)))
        geAddHilightLine(hs list(list(x2 y1) list(x2 y2)))
        geAddHilightLine(hs list(list(x2 y2) list(x1 y2)))
        geAddHilightLine(hs list(list(x1 y2) list(x1 y1)))

        flResultBBox=flUnion(flResultBBox b)
        flMatches=flMatches+1
        return(b)
    )
)

; Guide line from the origin to the center of bb (edit-cell coordinates).
procedure(flMarkGuide(hs bb)
    prog((b)
        b=flDisplayBBox(bb)
        unless(b return(nil))
        geAddHilightLine(hs list(flDisplayPoint(0:0) flCenter(b)))
        return(t)
    )
)

; Instance target with no instance-name label in the layout.
; Edit cell: the instances of the matching cell are selected (no mark);
; the CIW shows Name, Library and Cell. BOTTOM: placements below the edit cell
; get a box + X. Return the number of hits.
; Layout master `master` is a bundle of one of the target cells: named
; <cell>_x<N> (a_saio_x2) and holding that cell directly. Returns the
; target master, or nil.
procedure(flBundleOf(master cells)
    prog((name found prefix rest)
        name=car(errset(master~>cellName nil))
        unless(stringp(name) return(nil))

        foreach(t0 cells
            unless(found
                prefix=strcat(t0~>cellName "_x")

                when(
                    strlen(name)>strlen(prefix) &&
                    substring(name 1 strlen(prefix))==prefix

                    rest=substring(name strlen(prefix)+1)

                    when(
                        rexMatchp("^[0-9]+$" rest) &&
                        exists(rec flChildList(master) cadr(rec)==t0)

                        found=t0
                    )
                )
            )
        )

        return(found)
    )
)

procedure(flFindCellTarget(cv name cellInfo hs occurrences)
    prog((cells hits selected boxed bb info mosaics elems xy row col tr
          all held inner bundles bundleName ball)
        cells=flCellMatches(cellInfo)
        hits=0
        boxed=0
        mosaics=0
        elems=0
        inner=0
        bundles=0

        unless(cells return(0))

        foreach(inst cv~>instances
            when(inst~>objType=="inst" && member(inst~>master cells)
                flSelect(inst)
                flCellSelects=flCellSelects+1
                unless(member(inst flCellSelected)
                    flCellSelected=cons(inst flCellSelected)
                )
                flResultBBox=flUnion(
                    flResultBBox
                    flDisplayBBox(inst~>bBox)
                )
                selected=cons(inst selected)
                hits=hits+1

                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; selected Name=%s Library=%s Cell=%s"
                    name inst~>name inst~>libName inst~>cellName
                ))
            )
        )

        ; Mosaic of the cell in the edit cell: the whole mosaic is selected
        ; (which element holds which bit is not known).
        foreach(m cv~>mosaics
            info=flMosaicInfo(m)

            when(info && member(car(info) cells)
                flSelect(m)
                flCellSelects=flCellSelects+1
                unless(member(m flCellSelected)
                    flCellSelected=cons(m flCellSelected)
                )
                flResultBBox=flUnion(
                    flResultBBox
                    flDisplayBBox(m~>bBox)
                )
                selected=cons(m selected)
                hits=hits+1

                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; selected mosaic Name=%s Library=%s Cell=%s (%dx%d, bit order not known)"
                    name nth(7 info) car(info)~>libName car(info)~>cellName
                    nth(3 info) nth(4 info)
                ))
            )
        )

        ; Bundle (<cell>_x<N>) in the edit cell: selected as the cell.
        foreach(inst cv~>instances
            held=if(inst~>objType=="inst" then
                flBundleOf(inst~>master cells)
            else
                nil
            )

            when(held
                flSelect(inst)
                flCellSelects=flCellSelects+1
                unless(member(inst flCellSelected)
                    flCellSelected=cons(inst flCellSelected)
                )
                flResultBBox=flUnion(
                    flResultBBox
                    flDisplayBBox(inst~>bBox)
                )
                selected=cons(inst selected)
                hits=hits+1

                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; selected Name=%s Cell=%s (holds %s, bit order not known)"
                    name inst~>name inst~>cellName held~>cellName
                ))
            )
        )

        foreach(m cv~>mosaics
            info=flMosaicInfo(m)
            held=if(info then flBundleOf(car(info) cells) else nil)

            when(held
                flSelect(m)
                flCellSelects=flCellSelects+1
                unless(member(m flCellSelected)
                    flCellSelected=cons(m flCellSelected)
                )
                flResultBBox=flUnion(
                    flResultBBox
                    flDisplayBBox(m~>bBox)
                )
                selected=cons(m selected)
                hits=hits+1

                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; selected mosaic Name=%s Cell=%s (%dx%d, holds %s, bit order not known)"
                    name nth(7 info) car(info)~>cellName
                    nth(3 info) nth(4 info) held~>cellName
                ))
            )
        )

        when(length(selected)>1
            flWarn(sprintf(nil
                "[S2L] %s: %d instances of %s - all selected, check which"
                name length(selected) car(cellInfo)
            ))
        )

        when(flBottomMode
            foreach(occ occurrences
                when(nth(3 occ)>0
                    ; Inside a bundle (a_saio_x2): plain box per unit and
                    ; one guide line per bundle.
                    held=flBundleOf(car(occ) cells)
                    ball=nil

                    foreach(rec flChildList(car(occ))
                        when(car(rec)=='inst && member(cadr(rec) cells)
                            bb=flTransformBox(
                                flTransformBox(cadr(rec)~>bBox nth(2 rec))
                                cadr(occ)
                            )

                            if(held then
                                when(flMarkBoxOnce(hs bb)
                                    inner=inner+1
                                    hits=hits+1
                                    ball=flUnion(ball bb)
                                )
                            else
                                when(flMarkBoxOnce(hs bb)
                                    boxed=boxed+1
                                    hits=hits+1
                                )
                            )
                        )

                        ; Mosaic placement: a plain box on every element,
                        ; one guide line to the whole mosaic.
                        when(car(rec)=='mosaic && member(cadr(rec) cells)
                            xy=nth(2 rec)
                            all=nil
                            row=0

                            while(row<nth(4 rec)
                                col=0

                                while(col<nth(5 rec)
                                    tr=list(
                                        list(
                                            car(xy)+col*nth(6 rec)
                                            cadr(xy)+row*nth(7 rec)
                                        )
                                        nth(3 rec)
                                        1.0
                                    )

                                    bb=flTransformBox(
                                        flTransformBox(cadr(rec)~>bBox tr)
                                        cadr(occ)
                                    )

                                    when(flMarkBoxOnce(hs bb)
                                        elems=elems+1
                                        hits=hits+1
                                        all=flUnion(all bb)
                                    )

                                    col=col+1
                                )

                                row=row+1
                            )

                            when(all
                                mosaics=mosaics+1
                            )
                        )
                    )

                    when(held && ball
                        bundles=bundles+1
                        bundleName=car(occ)~>cellName
                    )
                )
            )

            when(bundles>0
                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; %d %s in %d %s below this cell marked with box + X (bit order not known)"
                    name inner flCellListText(cells) bundles bundleName
                ))
            )

            when(mosaics>0
                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; %d mosaic placement(s) of %s below this cell, %d elements marked with box + X (bit order not known)"
                    name mosaics flCellListText(cells) elems
                ))
            )

            when(boxed>0
                flNote(sprintf(nil
                    "[S2L] %s: no instance-name label; %d placement(s) of %s below this cell marked with box + X"
                    name boxed flCellListText(cells)
                ))
            )
        )

        when(hits==0 && !flBottomMode
            flCellBelow=flCellListText(cells)

            flNote(sprintf(nil
                "[S2L] %s: cell %s is below this cell; use CURRENT TO BOTTOM"
                name flCellBelow
            ) t)
        )

        return(hits)
    )
)

; Layout masters named like the schematic cell the targets were saved in
; (same name first, else "<cell>_<suffix>").
procedure(flSourceCellMasters()
    prog((match)
        match=flCellNameMatch(
            flSourceCell
            flMasters
            car(errset(flBlockCellP(flSourceLib flSourceCell) nil))
        )
        flVariantNote(flSourceCell match)
        return(car(match))
    )
)

procedure(flSearchLayout(cv)
    prog((palette infos info occurrences index hs name kind pairs
          missingReason labelHits flLabelPaths matched targetHits point
          alertBefore marksBefore skipsBefore skipFlags skipFlag
          names ran groups choice hit
          gPath gPairs gScopes gReason gScore gInner innerHits srcLabeled
          scopesBefore occByMaster)

        palette=flPalette(cv)
        unless(palette
            error("Finder: no usable highlight layer.\n")
        )

        when(length(palette)<2
            flNote(
                "[FINDER] Only one distinct highlight color is available; targets are told apart by marker size."
            )
        )

        ; Phase 1: unique layout masters (both modes: blocks reached through
        ; the schematic may lie below the edit cell). CURRENT does not report
        ; hierarchy notes from this collection.
        flCollectMasters(cv 0 nil)

        ; BOTTOM: layout of the schematic cell the names were saved in.
        flSourceMasters=if(flBottomMode then flSourceCellMasters() else nil)

        foreach(m flSourceMasters
            unless(member(m flScopeSet)
                flScopeSet=cons(m flScopeSet)
            )
        )

        unless(flBottomMode
            flUnsupported=0
            flTraversalLimited=nil
        )

        scopesBefore=flScopeSet

        ; Phase 2: block decision per target, before expansion.
        foreach(target flSchTargets
            flNameTable[cadr(target)]=t
            info=nil
            skipsBefore=flBlockSkips
            flSkipNames=nil

            when(
                car(target)!='inst &&
                flFindMissingByPins &&
                caddr(target) &&
                !nth(3 target) &&
                !flTimeStopped

                ; Repeated block paths are expanded once per target.
                flGroupMemo=makeTable('flGroupMemo nil)

                groups=flExpandGroups(
                    cadr(target) nil caddr(target)
                    flSchInstances "/" 0 'top nil
                )

                ; info: list of (path pairs instMap scopes reason score)
                foreach(g groups
                    choice=if(nth(3 g)=='top then
                        flChooseScopes(cv cadr(g))
                    else
                        list(nth(3 g) nil)
                    )

                    info=cons(
                        list(
                            car(g) cadr(g) caddr(g)
                            car(choice) cadr(choice) nth(4 g) nth(5 g)
                        )
                        info
                    )

                    foreach(scope car(choice)
                        unless(member(scope flScopeSet)
                            flScopeSet=cons(scope flScopeSet)
                        )
                    )
                )

                info=reverse(info)
            )

            ; Instance target without any instance-name label: the cells
            ; that may be it are searched below the edit cell (BOTTOM).
            when(
                car(target)=='inst &&
                flBottomMode &&
                flSelectCellByName &&
                nth(4 target) &&
                !flLabelKnown(cadr(target))

                foreach(m flCellMatches(nth(4 target))
                    unless(member(m flCellTargets)
                        flCellTargets=cons(m flCellTargets)
                    )
                )
            )

            infos=cons(info infos)
            skipFlags=cons(flSkipNames skipFlags)
        )

        infos=reverse(infos)
        skipFlags=reverse(skipFlags)

        ; Time limit reached in the pin guide: no terminal guidance at all
        ; (a partial one would mislead); net labels are still marked.
        when(flTimeStopped
            infos=mapcar(lambda((x) nil) infos)
            flScopeSet=scopesBefore
        )

        ; Phase 3: placements that can hold a result.
        if(flBottomMode || flSubScopeP(cv) then
            flExpandOccurrences(cv list(0:0 "R0" 1.0) "/" 0)
        else
            flVisits=1
            flOccurrences=list(list(cv list(0:0 "R0" 1.0) "/" 0))
        )

        occurrences=reverse(flOccurrences)
        index=0

        ; Placements per layout master, for the block (pin guide) loops.
        occByMaster=makeTable('flOccByMaster nil)

        foreach(occ flOccurrences
            occByMaster[car(occ)]=cons(occ occByMaster[car(occ)])
        )

        foreach(target flSchTargets
            kind=car(target)
            name=cadr(target)
            pairs=caddr(target)
            missingReason=nth(3 target)
            info=car(infos)
            infos=cdr(infos)
            alertBefore=flAlertCount+flSoftCount
            marksBefore=flMatches+flCellSelects
            skipsBefore=flBlockSkips
            skipFlag=car(skipFlags)
            skipFlags=cdr(skipFlags)
            flSkipNames=skipFlag
            flCellBelow=nil

            flMarkScale=if(length(palette)>1 then 1.0 else 1.0+0.5*mod(index 4))

            hs=flHilight(
                flDisplayCV
                nth(mod(index length(palette)) palette)
                'S2L
            )

            unless(hs
                error("Finder: highlight creation failed.\n")
            )

            labelHits=nil
            flLabelPaths=nil
            srcLabeled=nil
            targetHits=0

            foreach(occ occurrences
                flHardTimeCheck()
                matched=nil

                ; CURRENT: net labels and instance targets in the edit cell only.
                ; BOTTOM: every label with the name, anywhere below.
                foreach(label
                    if(flBottomMode || nth(3 occ)==0 then
                        car(flLayoutIndex(car(occ)))
                    else
                        nil
                    )

                    when(label~>theLabel==name
                        point=dbTransformPoint(
                            label~>xy cadr(occ)
                        )

                        flMark(
                            hs
                            point
                            dbTransformBBox(
                                label~>bBox cadr(occ)
                            )
                        )

                        when(nth(3 occ)==0
                            flSelect(label)
                        )

                        targetHits=targetHits+1
                        matched=t
                    )
                )

                when(matched
                    unless(member(car(occ) labelHits)
                        labelHits=cons(
                            car(occ) labelHits
                        )
                    )

                    ; Label inside a block: no terminal marks anywhere in
                    ; that block (including blocks nested in it).
                    when(nth(3 occ)>0
                        flLabelPaths=cons(nth(2 occ) flLabelPaths)
                    )

                    ; Label in the saved cell's layout: its own endpoints
                    ; (not those of blocks below it) get no terminal marks.
                    when(member(car(occ) flSourceMasters)
                        srcLabeled=t
                    )
                )

                when(!matched && kind=='inst && !flBottomMode && nth(3 occ)==0
                    foreach(inst cv~>instances
                        when(
                            inst~>objType=="inst" &&
                            inst~>name==name

                            flMark(
                                hs inst~>xy inst~>bBox
                            )
                            flSelect(inst)
                            targetHits=targetHits+1
                        )
                    )
                )
            )

            ; Instance target without an instance-name label: the layout
            ; instance of the same cell (selected, or box + X below).
            when(
                kind=='inst &&
                targetHits==0 &&
                flSelectCellByName &&
                nth(4 target)

                targetHits=flFindCellTarget(
                    cv name nth(4 target) hs occurrences
                )
            )

            ; A net label inside a block replaces terminal guidance there.
            when(kind!='inst && flFindMissingByPins
                if(pairs && !missingReason then
                    foreach(g info
                        gPath=car(g)
                        gPairs=cadr(g)
                        flCurrentSchInsts=caddr(g)
                        gScopes=nth(3 g)
                        gReason=nth(4 g)
                        gScore=nth(5 g)
                        gInner=nth(6 g)

                        ; Inner name of the net in this block (csm_CRCRD
                        ; outside, CRCRD inside); nil when it is the same.
                        when(gInner==name gInner=nil)

                        ; Saved cell's own endpoints, net label found there.
                        when(srcLabeled && gPath=="/"
                            gScopes=nil
                            gReason=nil
                        )

                        if(gScopes then
                            names=flIdentityNames(gPairs)
                            ran=nil

                            foreach(scope gScopes
                                unless(member(scope labelHits)
                                    hit=nil

                                    foreach(occ occByMaster[scope]
                                        when(
                                            !flUnderLabel(nth(2 occ) flLabelPaths) &&
                                            !flSoftTimeUp()

                                            unless(hit
                                                hit=t
                                                ran=cons(scope ran)

                                                flDetail(sprintf(nil
                                                    "[PIN-FIND] BLOCK net=%L layout=%L instanceLabels=%d/%d%s"
                                                    name
                                                    scope~>cellName
                                                    flIdentityCount(scope names)
                                                    length(names)
                                                    flViaText(gPath gScore)
                                                ))
                                            )

                                            ; A label with the inner net name in
                                            ; this block is the mark; else terminals.
                                            innerHits=if(gInner then
                                                flMarkInnerLabels(occ gInner hs)
                                            else
                                                0
                                            )

                                            if(innerHits>0 then
                                                targetHits=targetHits+innerHits

                                                when(nth(3 occ)>0
                                                    flLabelPaths=cons(nth(2 occ) flLabelPaths)
                                                )

                                                flDetail(sprintf(nil
                                                    "[PIN-FIND] INNER LABEL net=%L as %L in %s; terminals not marked"
                                                    name gInner nth(2 occ)
                                                ))
                                            else
                                                flMarkRequiredPins(
                                                    occ name gPairs hs
                                                )
                                            )
                                        )
                                    )
                                )
                            )

                            when(length(ran)>1
                                flWarn(sprintf(nil
                                    "[S2L] %s: found in several blocks (%s) - all marked"
                                    name
                                    flCellListText(reverse(ran))
                                ))
                            )
                        else
                            when(targetHits==0
                                flScopeProblems=flScopeProblems+1

                                flSoftAlert(sprintf(nil
                                    "[S2L] %s: block layout not found (%s)"
                                    name
                                    gReason
                                ))
                            )
                        )
                    )
                else
                    when(targetHits==0
                        flScopeProblems=flScopeProblems+1

                        flSoftAlert(sprintf(nil
                            "[S2L] %s: no connection data (%s)"
                            name
                            missingReason ||
                                "No instance terminals on this signal"
                        ))
                    )
                )
            )

            when(kind=='inst && targetHits==0
                flSoftAlert(
                    if(flCellBelow then
                        sprintf(nil
                            "[S2L] %s: not in this cell (inside %s). Use CURRENT TO BOTTOM."
                            name flCellBelow
                        )
                    else
                        sprintf(nil "[S2L] %s: not found" name)
                    )
                )
            )

            ; Some pins were skipped (inside a block) while others were
            ; marked: say so in the CIW.
            when(
                !flBottomMode &&
                flSkipNames &&
                flMatches+flCellSelects>marksBefore

                flNote(sprintf(nil
                    "[S2L] %s: pins inside %s not marked in CURRENT - use CURRENT TO BOTTOM"
                    name
                    flNameListText(flSkipNames)
                ))
            )

            when(flMatches+flCellSelects==marksBefore
                flZeroTargets=flZeroTargets+1

                when(
                    flAlertCount+flSoftCount==alertBefore &&
                    !and(flTimeStopped kind!='inst)

                    flSoftAlert(
                        if(flSkipNames then
                            sprintf(nil
                                "[S2L] %s: not in this cell (inside %s). Use CURRENT TO BOTTOM."
                                name
                                flNameListText(flSkipNames)
                            )
                        else
                            sprintf(nil
                                "[S2L] %s: not found"
                                name
                            )
                        )
                    )
                )
            )

            index=index+1
        )

        ; Blocks found by cell name: clear the layout selection and keep
        ; only those blocks selected.
        when(flCellSelected
            unless(errset(geDeselectAll(flSearchWindow) nil)
                errset(geDeselectAllFig(cv) nil)
            )

            foreach(fig flCellSelected
                errset(geSelectFig(fig) nil)
            )

            flSelLabelCount=0
            flSelInstCount=length(flCellSelected)
        )

        return(t)
    )
)

procedure(flProbe(win path isNet index)
    prog((r probe offset lpp count key order)
        ; One probe per net / instance path in a search.
        key=strcat(if(isNet then "N:" else "I:") path)
        when(flProbeSeen && flProbeSeen[key] return(t))

        order=if(flProbeOrder then flProbeOrder else flProbeLPPs)
        count=length(order)
        offset=0

        while(offset<count && !probe
            lpp=nth(
                mod(index+offset count)
                order
            )

            r=if(isNet then
                errset(
                    geAddNetProbe(win lpp path)
                    nil
                )
            else
                errset(
                    geAddInstProbe(win lpp path)
                    nil
                )
            )

            when(r && car(r)
                probe=car(r)
            )

            offset=offset+1
        )

        if(probe then
            when(isNet
                errset(
                    probe~>probeDisplayStyle="flight"
                    nil
                )
            )

            flProbeRecords=cons(
                list('L2S win probe)
                flProbeRecords
            )
            flMatches=flMatches+1

            when(flProbeSeen
                flProbeSeen[key]=t
            )
        else
            flSoftAlert(sprintf(nil
                "[L2S] %s: probe failed"
                path
            ))
        )

        return(probe)
    )
)

procedure(flTextHilight(cv win index)
    prog((display packet color packetName hs r)
        display=drGetDisplay("display")
        unless(display return(nil))

        packet=drFindPacket(
            display
            if(flProbeOrder then
                car(nth(mod(index length(flProbeOrder)) flProbeOrder))
            else
                sprintf(nil "y%d" mod(index 10))
            )
        )

        when(packet
            color=nth(5 packet)
            unless(color && drGetColor(display color)
                color=nth(4 packet)
            )
        )

        unless(color && drGetColor(display color)
            return(nil)
        )

        packetName=sprintf(
            nil "flTextPacket%d" index
        )

        r=errset(
            geCreatePacket(
                win packetName "solid" "solid"
                color color 4 nil
            )
            nil
        )
        unless(r return(nil))

        hs=geCreateHilightSet(cv packetName)

        when(hs
            hs~>enable=t
            flHilightRecords=cons(
                list('L2S hs)
                flHilightRecords
            )
        )

        return(hs)
    )
)

procedure(flSignalZoom(cv name ownerBBox path)
    prog((info)
        if(ownerBBox then
            flResultBBox=flUnion(
                flResultBBox ownerBBox
            )
        else
            foreach(net cv~>nets
                when(flContains(net~>name name)
                    foreach(fig net~>figs
                        flResultBBox=flUnion(
                            flResultBBox fig~>bBox
                        )
                    )
                )
            )
        )

        info=flEndpointInfo(cv name)

        foreach(pair car(info)
            flDetail(sprintf(nil
                "[L2S] CONNECT net=%L instance=%s pin=%s"
                name
                flJoin(path car(pair))
                cadr(pair)
            ))

            unless(ownerBBox
                foreach(inst cv~>instances
                    when(flContains(inst~>name car(pair))
                        flResultBBox=flUnion(
                            flResultBBox inst~>bBox
                        )
                    )
                )
            )
        )

        return(t)
    )
)

procedure(flChildSchematic(inst)
    prog((master key cached child r)
        master=inst~>master
        unless(master return(nil))

        when(master~>cellViewType=="schematic"
            return(master)
        )

        key=list(
            master~>libName
            master~>cellName
            flSchViewName
        )

        cached=assoc(key flViewCache)
        when(cached return(cadr(cached)))

        when(ddGetObj(car(key) cadr(key) caddr(key))
            r=errset(
                dbOpenCellViewByType(
                    car(key) cadr(key) caddr(key) "" "r"
                )
                nil
            )

            if(r && car(r) then
                child=car(r)
                flOpenedViews=cons(
                    child flOpenedViews
                )
            else
                flNote(sprintf(nil
                    "[L2S] Cannot open %s/%s/%s"
                    car(key) cadr(key) caddr(key)
                ) t)
            )
        )

        flViewCache=cons(
            list(key child)
            flViewCache
        )

        return(child)
    )
)

procedure(flMarkFound(name)
    unless(member(name flFoundNames)
        flFoundNames=cons(name flFoundNames)
    )
    t
)

; ---- netcon: two nets with different names shorted by a cell ----
; Nets connected to `name` through netcon instances in cv. Each member of
; an iterated netcon (IRX144_2<127:0>) joins the same bit position of its
; two terminals' nets: OUT TMBIT<0> <-> IN ICAMTMBIT<2>.
; Rule for a cell: nil (not a netcon cell), t (any terminal pair) or the
; two terminal names that are passed through.
procedure(flNetconRule(cellName)
    prog((rule)
        foreach(e flNetconCells
            cond(
                (rule nil)
                (stringp(e)
                    when(e==cellName rule=t)
                )
                (listp(e)
                    when(car(e)==cellName rule=cdr(e))
                )
            )
        )
        return(rule)
    )
)

; True when terminals a -> b are passed through under rule.
procedure(flNetconPairP(rule a b)
    prog(()
        when(rule==t return(t))
        unless(listp(rule) return(nil))

        return(
            or(
                and(a==car(rule) b==cadr(rule))
                and(a==cadr(rule) b==car(rule))
            )
        )
    )
)

procedure(flNetconPartners(cv name)
    prog((r sig out it pos inst width owidth names p rule)
        r=errset(dbFindSigByName(cv name) nil)
        sig=if(r then car(r) else nil)
        unless(sig return(nil))

        r=errset(sig~>memInstTerms nil)

        foreach(rec if(r then car(r) else nil)
            it=car(rec)
            pos=cadr(rec)
            inst=car(errset(it~>inst nil))

            rule=if(inst then flNetconRule(car(errset(inst~>cellName nil))) else nil)

            when(
                inst &&
                numberp(pos) &&
                rule

                width=car(errset(dbGetNameNumBit(it~>name) nil))

                foreach(other inst~>instTerms
                    when(
                        other!=it &&
                        numberp(width) && width>0 &&
                        flNetconPairP(rule it~>name other~>name)

                        owidth=car(errset(dbGetNameNumBit(other~>name) nil))
                        names=flExpand(flNetName(other))

                        ; Same instance member and same bit on the other side.
                        when(numberp(owidth) && owidth==width && names
                            p=nth(pos names)

                            when(stringp(p) && p!=name && !member(p out)
                                out=cons(p out)
                            )
                        )
                    )
                )
            )
        )

        return(reverse(out))
    )
)

; ---- L2S connectivity trace ----
; From a found net, follow the same signal under other names:
;   netcon / wire_couple   same cell (both modes)
;   DOWN  into a block cell by pin bit position (BOTTOM): iCAMTMBIT<6> ->
;         Imain1 pin CAMTMBIT<255:0> bit 6 -> CAMTMBIT<6> inside, and on
;         through the block instance that holds that bit (a_saiox8 #0).
;   UP    from a pin of the cell to the parent net (BOTTOM, only when the
;         cell was entered by descend; flTraceUpLevels levels).
; Every net is probed once in the target's color; at most flTraceMaxNets.

; Number of instance levels in a path ("/" -> 0, "/I5/I7" -> 2).
procedure(flPathDepth(path)
    length(parseString(path "/"))
)

; Window top cellview (the cell the user descended from).
procedure(flWindowTop(win)
    prog((r)
        r=errset(geGetTopLevelCellView(win) nil)
        when(r && car(r) return(car(r)))
        r=errset(win~>topCellView nil)
        when(r && car(r) return(car(r)))
        return(nil)
    )
)

; Instance in cv whose (expanded) name holds member `elem`.
; Return (inst memberIndex) or nil.
procedure(flFindMember(cv elem)
    prog((found names i)
        foreach(inst cv~>instances
            unless(found
                cond(
                    (inst~>name==elem
                        found=list(inst 0)
                    )
                    (t
                        names=flExpand(inst~>name)
                        i=0

                        foreach(n names
                            when(!found && n==elem
                                found=list(inst i)
                            )
                            i=i+1
                        )
                    )
                )
            )
        )

        return(found)
    )
)

; Parent of the cell at `path` in the window hierarchy.
; Return (parentCv parentPath inst memberIndex) or nil.
procedure(flParentOf(win path)
    prog((elems top cur hit parentPath r)
        elems=parseString(path "/")
        unless(elems return(nil))

        top=flWindowTop(win)
        unless(top return(nil))

        cur=top
        parentPath="/"

        foreach(e reverse(cdr(reverse(elems)))
            when(cur
                hit=flFindMember(cur e)
                r=if(hit then errset(flChildSchematic(car(hit)) nil) else nil)
                cur=if(r then car(r) else nil)
                parentPath=flJoin(parentPath e)
            )
        )

        unless(cur return(nil))

        hit=flFindMember(cur car(last(elems)))
        unless(hit return(nil))

        return(list(cur parentPath car(hit) cadr(hit)))
    )
)

; Net inside block schematic `child` on terminal `termName`, bit `bit`.
procedure(flTermMemberNet(child termName bit)
    prog((names name)
        foreach(term child~>terminals
            when(!names && term~>name==termName
                names=flExpand(flNetName(term) || termName)
            )
        )

        unless(names
            names=flExpand(termName)
        )

        name=if(names then nth(bit names) else nil)
        return(if(stringp(name) then name else nil))
    )
)

; DOWN: (childCv childPath innerNet inst) for every block-cell instance
; on net `name` in cv.
procedure(flTraceDown(cv path name)
    prog((r sig out it pos inst width child m im bit inner)
        r=errset(dbFindSigByName(cv name) nil)
        sig=if(r then car(r) else nil)
        unless(sig return(nil))

        r=errset(sig~>memInstTerms nil)

        foreach(rec if(r then car(r) else nil)
            it=car(rec)
            pos=cadr(rec)
            inst=car(errset(it~>inst nil))

            when(
                inst &&
                numberp(pos) &&
                !flPinSymbolP(inst) &&
                !flNetconRule(car(errset(inst~>cellName nil))) &&
                car(errset(flBlockCellP(inst~>libName inst~>cellName) nil))

                r=errset(flChildSchematic(inst) nil)
                child=if(r then car(r) else nil)
                width=car(errset(dbGetNameNumBit(it~>name) nil))

                when(child && numberp(width) && width>0
                    m=fix(pos/width)
                    bit=mod(pos width)
                    im=car(errset(dbGetMemName(inst~>name m) nil)) || inst~>name
                    inner=flTermMemberNet(child it~>name bit)

                    when(inner
                        out=cons(list(child flJoin(path im) inner inst) out)
                    )
                )
            )
        )

        return(reverse(out))
    )
)

; UP: (parentCv parentPath parentNet) for net `name` when it is a pin of
; the cell at `path`.
procedure(flTraceUp(win cv path name)
    prog((r sig parent pcv ppath inst m out term idx width it names p)
        when(path=="/" || path=="" return(nil))

        r=errset(dbFindSigByName(cv name) nil)
        sig=if(r then car(r) else nil)
        unless(sig return(nil))

        r=errset(sig~>memTerms nil)
        unless(r && car(r) return(nil))

        parent=flParentOf(win path)
        unless(parent return(nil))

        pcv=nth(0 parent)
        ppath=nth(1 parent)
        inst=nth(2 parent)
        m=nth(3 parent)

        foreach(rec car(r)
            term=car(rec)
            idx=cadr(rec)
            it=nil
            width=car(errset(dbGetNameNumBit(term~>name) nil))

            when(numberp(idx) && numberp(width) && width>0
                foreach(x inst~>instTerms
                    when(x~>name==term~>name
                        it=x
                    )
                )

                when(it
                    names=flExpand(flNetName(it))
                    p=if(names then nth(m*width+idx names) else nil)

                    when(stringp(p)
                        out=cons(list(pcv ppath p) out)
                    )
                )
            )
        )

        return(out)
    )
)

; Probe one traced net. zoom: nil = net shapes (displayed cell),
; a bBox = that area, 'none = no zoom (outside the displayed cell).
procedure(flTraceProbe(win cv path name zoom index)
    when(flProbe(win flJoin(path name) t index)
        if(zoom then
            unless(zoom=='none
                flResultBBox=flUnion(flResultBBox zoom)
            )
        else
            flSignalZoom(cv name nil path)
        )
    )
)

procedure(flTraceNet(cv path name ownerBBox win index)
    prog((queue node ncv npath nname nzoom nup key next zoom minDepth)
        key=strcat(path "|" name)
        when(flTraceSeen[key] return(t))
        flTraceSeen[key]=t

        minDepth=flPathDepth(path)-flTraceUpLevels
        ; Node: (cv path name zoom message canUp). UP is taken only on the
        ; outside chain (start net, nets reached by UP and their netcon
        ; partners), never back up from a net reached by DOWN.
        queue=list(list(cv path name if(ownerBBox then ownerBBox else nil) "" t))

        ; Time limit: stop tracing; nets probed so far stay.
        while(queue && !flSoftTimeUp()
            node=car(queue)
            queue=cdr(queue)
            ncv=nth(0 node)
            npath=nth(1 node)
            nname=nth(2 node)
            nzoom=nth(3 node)
            nup=nth(5 node)
            next=nil

            ; Same cell: netcon / wire_couple.
            foreach(p flNetconPartners(ncv nname)
                next=cons(list(ncv npath p nzoom
                    sprintf(nil "[L2S] NETCON %s = %s (cell %s)"
                        nname p ncv~>cellName
                    )
                    nup
                ) next)
            )

            when(flBottomMode && flTraceDown
                foreach(d flTraceDown(ncv npath nname)
                    ; Zoom: inherited; the block instance when leaving the
                    ; displayed cell; nothing outside it.
                    zoom=nzoom

                    unless(zoom
                        zoom=if(npath==flDisplayPath then
                            car(errset(nth(3 d)~>bBox nil)) || 'none
                        else
                            'none
                        )
                    )

                    ; Back into the displayed cell (from its parent).
                    when(nth(1 d)==flDisplayPath
                        zoom=nil
                    )

                    next=cons(list(nth(0 d) nth(1 d) nth(2 d) zoom
                        sprintf(nil "[L2S] DOWN %s -> %s (cell %s)"
                            nname flJoin(nth(1 d) nth(2 d)) nth(0 d)~>cellName
                        )
                        nil
                    ) next)
                )
            )

            when(
                nup &&
                flBottomMode &&
                flTraceUpLevels>0 &&
                flPathDepth(npath)-1>=minDepth

                foreach(u flTraceUp(win ncv npath nname)
                    next=cons(list(nth(0 u) nth(1 u) nth(2 u)
                        if(nth(1 u)==flDisplayPath then nil else 'none)
                        sprintf(nil "[L2S] UP %s -> %s (cell %s)"
                            nname flJoin(nth(1 u) nth(2 u)) nth(0 u)~>cellName
                        )
                        t
                    ) next)
                )
            )

            foreach(n reverse(next)
                key=strcat(nth(1 n) "|" nth(2 n))

                unless(flTraceSeen[key]
                    flTraceSeen[key]=t

                    if(flTraceCount<flTraceMaxNets then
                        flTraceCount=flTraceCount+1
                        flNote(nth(4 n))
                        flTraceProbe(win nth(0 n) nth(1 n) nth(2 n) nth(3 n) index)
                        queue=append(queue list(n))
                    else
                        unless(flTraceLimited
                            flTraceLimited=t
                            flNote(sprintf(nil
                                "[L2S] Trace stopped at %d nets (flTraceMaxNets)."
                                flTraceMaxNets
                            ))
                        )
                    )
                )
            )
        )

        return(t)
    )
)

; True when schematic cell `cell` is the cell of the saved layout labels
; (same name, or the layout name is a variant: temp_crc_gen, crc_gen_u1).
procedure(flLaySourceP(cell)
    prog((src n m)
        src=flLaySourceCell
        unless(stringp(src) && stringp(cell) return(nil))
        when(src==cell return(t))

        n=strlen(cell)
        m=strlen(src)

        when(m>n+1
            when(substring(src 1 n+1)==strcat(cell "_") return(t))
            when(substring(src m-n n+1)==strcat("_" cell) return(t))
        )

        return(nil)
    )
)

; True when schematic `cv` is, or contains below it, the schematic of the
; saved layout cell. Cached per cell for the run.
procedure(flHasLaySource(cv stack)
    prog((key state result child)
        key=strcat(cv~>libName "/" cv~>cellName)
        state=flLaySourceTable[key]

        when(state=='yes return(t))
        when(state return(nil))

        when(flLaySourceP(cv~>cellName)
            flLaySourceTable[key]='yes
            return(t)
        )

        when(member(key stack) return(nil))
        when(flSoftTimeUp() return(nil))
        flLaySourceTable[key]='pending

        foreach(inst cv~>instances
            when(!result && inst~>objType=="inst" && !flPinSymbolP(inst)
                child=car(errset(flChildSchematic(inst) nil))

                when(child && flHasLaySource(child cons(key stack))
                    result=t
                )
            )
        )

        flLaySourceTable[key]=if(result then 'yes else 'no)
        return(result)
    )
)

; True when every L2S target was found as a net in the searched cell.
procedure(flAllTopFound()
    prog((all)
        all=t
        foreach(name flLayTargets
            unless(flTopFound[name] all=nil)
        )
        return(all)
    )
)

procedure(flWalkSchematic(cv path ownerBBox depth stack win)
    prog((key index r sig found hs bb child members unsupported skip)
        ; Time limit: stop walking; nets probed so far stay.
        when(flSoftTimeUp() return(nil))

        when(flVisits>=flMaxVisits || depth>flMaxDepth
            flTraversalLimited=t
            return(nil)
        )

        key=list(cv~>libName cv~>cellName cv~>viewName)

        when(member(key stack)
            flTraversalLimited=t
            return(nil)
        )

        flVisits=flVisits+1
        index=0

        foreach(name flLayTargets
            ; Found in the searched cell: lower cells are reached by the
            ; connectivity trace, not by name (same-name nets there are
            ; other signals).
            ; Not in the searched cell: below it only the schematic of the
            ; layout cell the label was saved in (first pass), so same-name
            ; nets of other cells are not used.
            skip=or(
                and(depth>0 flTopFound[name])
                and(depth>0 flLayRestrict !flLaySourceP(cv~>cellName))
            )
            r=if(skip then nil else errset(dbFindSigByName(cv name) nil))
            sig=if(r then car(r) else nil)
            found=skip
            hs=nil

            if(sig then
                found=t
                flMarkFound(name)

                when(depth==0
                    flTopFound[name]=t
                )

                when(flProbe(win flJoin(path name) t index)
                    flSignalZoom(
                        cv name ownerBBox path
                    )
                )

                ; Same signal under other names (netcon, blocks, parent),
                ; traced from the searched cell only. Same-name nets found
                ; in lower cells are unrelated nets and are not traced.
                when(
                    and(
                        flFollowNetcons
                        or(depth==0 and(flLayRestrict flLaySourceP(cv~>cellName)))
                    )

                    flTraceNet(cv path name ownerBBox win index)
                )
            else
                foreach(inst cv~>instances
                    when(
                        !found &&
                        !flPinSymbolP(inst) &&
                        flContains(inst~>name name)

                        found=t
                        flMarkFound(name)

                        when(
                            flProbe(
                                win flJoin(path name) nil index
                            )

                            bb=ownerBBox || inst~>bBox
                            flResultBBox=flUnion(
                                flResultBBox bb
                            )
                        )
                    )
                )
            )

            unless(found
                foreach(fig cv~>shapes
                    when(flText(fig)==name && fig~>bBox
                        flMarkFound(name)
                        bb=ownerBBox || fig~>bBox
                        flResultBBox=flUnion(
                            flResultBBox bb
                        )

                        if(depth==0 then
                            unless(hs
                                hs=flTextHilight(
                                    cv win index
                                )
                            )

                            if(hs then
                                geAddHilightLine(
                                    hs
                                    list(
                                        0:0
                                        flCenter(fig~>bBox)
                                    )
                                )
                                flMatches=flMatches+1
                            else
                                flSoftAlert(sprintf(nil
                                    "[L2S] Text highlight failed: %L"
                                    name
                                ))
                            )
                        else
                            flWarn(sprintf(nil
                                "[L2S] TEXT ONLY at %s; zoom to ancestor symbol"
                                flJoin(path name)
                            ))
                        )
                    )
                )
            )

            index=index+1
        )

        ; First pass: inside the saved layout cell's schematic the trace has
        ; done the work; elsewhere only cells that contain it are entered.
        when(
            and(
                flBottomMode
                !and(depth==0 flAllTopFound())
                !and(depth>0 flLayRestrict flLaySourceP(cv~>cellName))
            )

            foreach(inst cv~>instances
                if(inst~>objType=="inst" then
                    unless(flPinSymbolP(inst)
                        child=flChildSchematic(inst)

                        when(and(child or(!flLayRestrict flHasLaySource(child nil)))
                            members=flExpand(inst~>name)

                            unless(members
                                flNote(sprintf(nil
                                    "[L2S] Unsupported instance name: %L"
                                    inst~>name
                                ) t)
                            )

                            foreach(memberName members
                                flWalkSchematic(
                                    child
                                    flJoin(path memberName)
                                    ownerBBox || inst~>bBox
                                    depth+1
                                    cons(key stack)
                                    win
                                )
                            )
                        )
                    )
                else
                    unsupported=cons(inst unsupported)
                )
            )

            foreach(m cv~>mosaics
                unless(member(m unsupported)
                    unsupported=cons(m unsupported)
                )
            )

            flUnsupported=flUnsupported+length(unsupported)
        )

        return(t)
    )
)

; Summary window. Modeless, so layout work can go on without closing it.
; It closes by itself after flSummaryCloseSeconds; a new search closes the
; previous one. Modal only as a fallback.
; The ?name symbol of a dialog box holds the box itself.

; serial: close only that window (timer); nil: whichever is open.
; The box is closed exactly as typed in the CIW: hiDBoxOK(<box name>).
procedure(flCloseSummary(@optional serial)
    prog(()
        unless(
            flSummaryOpen && flSummaryBox &&
            (!serial || serial==flSummarySerial)

            return(t)
        )

        flSummaryOpen=nil

        errset(
            evalstring(sprintf(nil "hiDBoxOK(%s)" get_pname(flSummaryBox)))
            nil
        )

        return(t)
    )
)

procedure(flShowSummary(text)
    prog((r name)
        flCloseSummary()

        flSummarySerial=flSummarySerial+1
        name=stringToSymbol(
            sprintf(nil "flFinderSummary%d" flSummarySerial)
        )

        r=errset(
            hiDisplayAppDBox(
                ?name name
                ?dboxBanner "Finder search summary"
                ?dboxText text
                ?dialogType hicWarningDialog
                ?dialogStyle 'modeless
                ?buttonLayout 'Close
            )
            nil
        )

        if(r then
            flSummaryBox=name
            flSummaryOpen=t

            when(flSummaryCloseSeconds>0
                errset(
                    hiRegTimer(
                        sprintf(nil "flCloseSummary(%d)" flSummarySerial)
                        fix(flSummaryCloseSeconds*10)
                    )
                    nil
                )
            )
        else
            printf(
                "[FINDER] Modeless summary window is not available; using a modal one.\n"
            )

            errset(
                hiDisplayAppDBox(
                    ?name 'flFinderWarning
                    ?dboxBanner "Finder search summary"
                    ?dboxText text
                    ?dialogType hicWarningDialog
                    ?buttonLayout 'Close
                )
                nil
            )
        )

        return(t)
    )
)

; " in /I1/I2" for a sub-path, "" for the searched cell.
procedure(flWhere(path)
    if(stringp(path) && path!="/" && path!="" then
        strcat(" in " path)
    else
        ""
    )
)

; "[S2L] text" -> "text" (popup lines).
procedure(flStripTag(message)
    prog((r)
        r=errset(
            if(rexCompile("^\\[[A-Z0-9-]+\\] *") then
                rexReplace(message "" 1)
            else
                message
            )
            nil
        )
        return(if(r && stringp(car(r)) then car(r) else message))
    )
)

procedure(flFinishReport(direction)
    prog((summary pinLine text count shown)
        summary=sprintf(nil
            "[FINDER] mode=%s visits=%d marks=%d warnings=%d notes=%d time=%s"
            flModeName()
            flVisits
            flMatches
            flWarningCount
            length(flNotes)
            flTimeText()
        )

        if(flVerbose then
            printf("%s\n" summary)
        else
            printf(
                "[%s] mode=%s; %s%s%s%s\n"
                if(direction=='S2L then "S2L" else "L2S")
                flModeName()
                if(flSelLabelCount>0 then
                    sprintf(nil "%d label%s selected, "
                        flSelLabelCount
                        if(flSelLabelCount==1 then "" else "s")
                    )
                else
                    ""
                )
                if(flSelInstCount>0 then
                    sprintf(nil "%d instance%s selected, "
                        flSelInstCount
                        if(flSelInstCount==1 then "" else "s")
                    )
                else
                    ""
                )
                cond(
                    (flMatches>0
                        sprintf(nil "%d mark%s" flMatches if(flMatches==1 then "" else "s"))
                    )
                    (flCellSelects>0
                        "no marks"
                    )
                    (t
                        "nothing marked"
                    )
                )
                sprintf(nil " (%s)" flTimeText())
            )
        )

        when(direction=='S2L
            pinLine=sprintf(nil
                "[PIN-FIND] expected=%d located=%d candidate=%d pinMarks=%d candidateMarks=%d labelOnlyMarks=%d missingIdentity=%d missingPin=%d ambiguous=%d scopeProblems=%d"
                flExpectedPins
                flFoundPins
                flCandidatePins
                flPinMarks
                flCandidateMarks
                flLabelOnlyMarks
                flMissingIdentity
                flMissingPins
                flAmbiguousPins
                flScopeProblems
            )

            summary=strcat(summary "\n" pinLine)

            when(flVerbose
                printf("%s\n" pinLine)

                when(flExpectedPins>0
                    printf(
                        "[PIN-FIND] Marks show required terminals. Routing connectivity was not checked.\n"
                    )
                )
            )

            when(flVerbose && flCandidatePins>0
                printf(
                    "[PIN-FIND] Box+X marks are CANDIDATE terminals. Verify the intended instance.\n"
                )
            )

            when(flVerbose && flLabelOnlyMarks>0
                printf(
                    "[PIN-FIND] LABEL ONLY donuts are on instance-name labels; the pin position was not found.\n"
                )
            )
        )

        flLastReport=cons(
            summary
            append(
                reverse(flWarnings)
                append(reverse(flNotes) reverse(flDetails))
            )
        )

        when(flVerbose && flDetailOmitted>0
            printf(
                "[FINDER] Detail lines suppressed=%d\n"
                flDetailOmitted
            )
        )

        when(flWarningCount>flWarningLimit
            printf(
                "[FINDER] More warnings saved. Run flPrintLastReport() for all details.\n"
            )
        )

        shown=append(
            reverse(flAlerts)
            if(flMatches+flCellSelects==0 then reverse(flSoftAlerts) else nil)
        )

        when(flShowWarningPopup && shown
            ; Short: mode and result, then the messages without their tags.
            text=sprintf(nil "mode=%s; %s\n\n"
                flModeName()
                if(flMatches>0 then
                    sprintf(nil "%d mark%s" flMatches if(flMatches==1 then "" else "s"))
                else
                    "nothing marked"
                )
            )

            count=0

            foreach(message shown
                when(count<flPopupLines
                    text=strcat(text flStripTag(message) "\n")
                )
                count=count+1
            )

            when(count>flPopupLines
                text=strcat(
                    text
                    sprintf(nil "... %d more: flPrintLastReport()\n" count-flPopupLines)
                )
            )

            flShowSummary(text)
        )

        return(t)
    )
)

procedure(flRun(cv direction)
    prog((flResultBBox flVisits flMatches flPinMarks flUnsupported
          flPartial flDetailCount flDetailOmitted flOccurrences flMasters
          flMasterCount flIndexTable flChildTable flNeedTable flNameTable
          flScopeSet flResolveCache flInsideCache flViewCache flOpenedViews
          flWarnings flWarningCount flNotes flZeroTargets flFoundNames
          flExpectedPins flFoundPins flCandidatePins flCandidateMarks
          flMissingIdentity flMissingPins flAmbiguousPins flScopeProblems
          flTraversalLimited flEIP flSearchWindow flDisplayCV
          flKindTable flMarkScale flLabelOnlyMarks flAlerts flAlertCount
          flKnownLabels flCurrentSchInsts flRootCV flDetails
          flSelLabelCount flSelInstCount flSoftAlerts flSoftCount
          flCellSelects flCellTargets flBlockSkips
          flDisplayPath flTraceSeen flTraceCount flTraceLimited flProbeSeen
          flTopFound flSkipNames flCellBelow flSourceMasters flLayRestrict
          allTargets flLaySourceTable
          flStartTime flTimeTicks flLastElapsed flTimeStopped flHardStopped
          flReachTable flMatchCache flGroupMemo flCellSelected flBoxSeen
          flProbeOrder
          flCellsBelowTable
          win r path shown)

        flVisits=0
        flMatches=0
        flPinMarks=0
        flUnsupported=0
        flDetailCount=0
        flDetailOmitted=0
        flWarningCount=0
        flZeroTargets=0
        flMasterCount=0
        flExpectedPins=0
        flFoundPins=0
        flCandidatePins=0
        flCandidateMarks=0
        flMissingIdentity=0
        flMissingPins=0
        flAmbiguousPins=0
        flScopeProblems=0
        flLabelOnlyMarks=0
        flAlertCount=0
        flSelLabelCount=0
        flSelInstCount=0
        flSoftCount=0
        flCellSelects=0
        flBlockSkips=0
        flDisplayPath="/"
        flTraceSeen=makeTable('flTraceSeen nil)
        flProbeSeen=makeTable('flProbeSeen nil)
        ; Probe colors in the same order as the layout marks.
        flProbeOrder=car(errset(flPalette(cv) nil))
        flTraceCount=0
        flTopFound=makeTable('flTopFound nil)
        flLaySourceTable=makeTable('flLaySourceTable nil)
        flCellsBelowTable=makeTable('flCellsBelowTable nil)
        flBoxSeen=makeTable('flBoxSeen nil)
        flStartTime=getCurrentTime()
        flTimeTicks=0
        flLastElapsed=0
        flReachTable=makeTable('flReachTable nil)
        flMatchCache=makeTable('flMatchCache nil)
        flGroupMemo=makeTable('flGroupMemo nil)

        flMarkScale=1.0
        flKindTable=makeTable('flKindTable nil)
        flRootCV=cv
        flIndexTable=makeTable('flIndexTable nil)
        flChildTable=makeTable('flChildTable nil)
        flNeedTable=makeTable('flNeedTable nil)
        flNameTable=makeTable('flNameTable nil)

        win=hiGetCurrentWindow()
        unless(win return(nil))

        shown=geGetWindowCellView(win)
        flSearchWindow=win
        flDisplayCV=shown
        flEIP=(cv!=shown && direction=='S2L)

        ; S2L supports EIP in both search modes.
        ; The existing L2S hierarchical-probe restriction remains.
        when(
            cv!=shown &&
            flBottomMode &&
            direction=='L2S

            printf(
                "[FINDER] Exit edit-in-place before this search.\n"
            )
            return(nil)
        )

        when(
            (direction=='S2L && !flSchTargets) ||
            (direction=='L2S && !flLayTargets && !flLayCellTargets)

            printf(
                "[FINDER] Capture names in the source window first.\n"
            )
            return(nil)
        )

        flLastReport=nil
        flClearOwned(direction)

        r=errset(
            if(direction=='S2L then
                flSearchLayout(cv)
            else
                errset(win~>probeTraverseHierarchy=nil nil)
                errset(win~>probeNetDisplayHierarchyLevel=0 nil)

                path=geGetInstHier()
                unless(stringp(path) path="/")

                while(
                    strlen(path)>1 &&
                    substring(path strlen(path) 1)=="/"

                    path=substring(
                        path 1 strlen(path)-1
                    )
                )

                flDisplayPath=path

                ; First pass: below the searched cell only inside the
                ; schematic of the layout cell the labels were saved in.
                flLayRestrict=and(
                    flBottomMode
                    flLaySourceCell
                    !flLaySourceP(cv~>cellName)
                )

                flWalkSchematic(
                    cv path nil 0 nil win
                )

                ; That cell is not below here: search every cell by name.
                when(flLayRestrict
                    flLayRestrict=nil
                    allTargets=flLayTargets
                    flLayTargets=nil

                    foreach(name allTargets
                        unless(member(name flFoundNames)
                            flLayTargets=cons(name flLayTargets)
                        )
                    )

                    flLayTargets=reverse(flLayTargets)

                    when(flLayTargets
                        flWalkSchematic(
                            cv path nil 0 nil win
                        )
                    )

                    flLayTargets=allTargets
                )

                ; Layout instances / mosaics saved by cell name.
                when(flLayCellTargets
                    flWalkCells(cv path nil 0 nil win)

                    ; Only the found blocks stay selected.
                    when(flCellSelected
                        unless(errset(geDeselectAll(win) nil)
                            errset(geDeselectAllFig(cv) nil)
                        )

                        foreach(fig flCellSelected
                            errset(geSelectFig(fig) nil)
                            flSelectionRecords=cons(
                                list('L2S fig)
                                flSelectionRecords
                            )
                        )

                        flSelLabelCount=0
                        flSelInstCount=length(flCellSelected)
                    )
                )
            )
            t
        )

        foreach(opened flOpenedViews
            errset(dbClose(opened) nil)
        )

        unless(r
            flClearOwned(direction)
            flResultBBox=nil
            flMatches=0
            flPinMarks=0
            flFoundPins=0
            flCellSelects=0

            flAlert(
                if(flHardStopped then
                    sprintf(nil
                        "[FINDER] Search stopped after %d s (too many connections); new Finder visuals cleared. Use CURRENT or add a net label."
                        flLastElapsed
                    )
                else
                    "[FINDER] Search failed; new Finder visuals cleared. See preceding CIW error."
                )
            )
        )

        ; Time limit reached: the marks found so far stay.
        when(r && flTimeStopped
            flAlert(
                if(direction=='S2L then
                    sprintf(nil
                        "[S2L] Pin guide stopped after %L s (too many connections); pin marks may be missing. Add a net label or use CURRENT."
                        flTimeoutSeconds
                    )
                else
                    sprintf(nil
                        "[L2S] Search stopped after %L s (too many cells); results may be incomplete. Use CURRENT or search from a lower cell."
                        flTimeoutSeconds
                    )
                )
            )
        )

        when(r && direction=='L2S
            foreach(name flLayTargets
                unless(member(name flFoundNames)
                    flZeroTargets=flZeroTargets+1

                    flSoftAlert(sprintf(nil
                        "[L2S] %s: not found"
                        name
                    ))
                )
            )

            foreach(cell flLayCellTargets
                unless(member(strcat("cell " cell) flFoundNames)
                    flZeroTargets=flZeroTargets+1

                    flSoftAlert(
                        if(!flBottomMode && car(errset(flCellsBelow(cv nil) nil)) then
                            sprintf(nil
                                "[L2S] cell %s: not in this cell (below it). Use CURRENT TO BOTTOM."
                                cell
                            )
                        else
                            sprintf(nil "[L2S] cell %s: not found" cell)
                        )
                    )
                )
            )
        )

        when(flTraversalLimited
            flPartial=t
            flNote(
                "[FINDER] Hierarchy visit/depth limit or recursive hierarchy encountered; results may be incomplete."
            )
        )

        when(flUnsupported>0
            flNote(sprintf(nil
                "[FINDER] Unsupported hierarchy objects skipped=%d"
                flUnsupported
            ) t)
        )

        flZoom(win)
        flFinishReport(direction)

        return(r && (flMatches>0 || flCellSelects>0) && !flPartial)
    )
)

procedure(findSchLay()
    prog((cv)
        flTrace(sprintf(nil "[S2L] mode=%s" flModeName()))

        cv=geGetEditCellView()
        unless(cv return(nil))

        case(cv~>cellViewType
            ("schematic"
                return(flCaptureSch(cv))
            )
            ("maskLayout"
                return(flRun(cv 'S2L))
            )
            (t
                printf("[S2L] Activate schematic or layout.\n")
            )
        )

        return(nil)
    )
)

procedure(findLaySch()
    prog((cv)
        flTrace(sprintf(nil "[L2S] mode=%s" flModeName()))

        cv=geGetEditCellView()
        unless(cv return(nil))

        case(cv~>cellViewType
            ("maskLayout"
                return(flCaptureLay())
            )
            ("schematic"
                return(flRun(cv 'L2S))
            )
            (t
                printf("[L2S] Activate layout or schematic.\n")
            )
        )

        return(nil)
    )
)

procedure(clearFindMarks()
    flClearOwned(nil)
    hiUpdate()

    printf(
        "[FINDER] mode=%s; Finder visuals cleared.\n"
        flModeName()
    )

    t
)

procedure(Toggle_current_or_current_to_bottom()
    flBottomMode=!flBottomMode
    flSchTargets=nil
    flLayTargets=nil
    flSourceCell=nil
    flSourceLib=nil
    flLaySourceCell=nil
    flLayCellTargets=nil

    printf(
        "[FINDER] mode=%s; capture source names again.\n"
        flModeName()
    )

    flBottomMode
)

; Default bindkeys. Set flSetBindKeys=nil before load() to skip them.
;   KP_1  findSchLay()      capture in schematic / search in layout
;   KP_3  findLaySch()      capture in layout / probe in schematic
;   KP_Decimal  clearFindMarks()  keypad dot (KP_Delete when NumLock is off)
;   KP_2  Toggle CURRENT / CURRENT TO BOTTOM
unless(boundp('flSetBindKeys) flSetBindKeys=t)

when(flSetBindKeys
    foreach(app list("Schematics" "Layout")
        errset(hiSetBindKey(app "<Key>KP_1" "findSchLay()") nil)
        errset(hiSetBindKey(app "<Key>KP_3" "findLaySch()") nil)
        errset(hiSetBindKey(app "<Key>KP_Decimal" "clearFindMarks()") nil)
        errset(hiSetBindKey(app "<Key>KP_Delete" "clearFindMarks()") nil)
        errset(
            hiSetBindKey(app "<Key>KP_2" "Toggle_current_or_current_to_bottom()")
            nil
        )
    )

)

printf(
    "[FINDER] Loaded %s; mode=%s%s\n"
    flVersion
    flModeName()
    if(flSetBindKeys then
        "; keys KP_1 S2L, KP_3 L2S, KP_Decimal clear, KP_2 mode"
    else
        ""
    )
)
