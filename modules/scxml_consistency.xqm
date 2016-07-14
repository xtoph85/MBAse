xquery version "3.0";

(:~
: User: mwe
: Date: 14.07.2016
: Time: 13:34
: To change this template use File | Settings | File Templates.
:)

module namespace scc = "http://www.w3.org/2005/07/scxml/consistency/";

import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';

import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';


declare function scc:getAllStates($scxml) as element()* {
    $scxml//(sc:state | sc:parallel | sc:final)
};

(: this function checks if a scxml-state is equal to another scxml-state from a refined scxml-model :)
declare function scc:isOriginalStateEqualToStateFromRefined($originalState, $refinedState) as xs:boolean {
    let $idOfStateOriginal := $originalState/@id
    let $idOfStateRefined := $refinedState/@id

    let $parentNodeOriginal := $originalState/..
    let $parentNodeRefined := $refinedState/..

    let $idOfParentNodeOriginal :=  $parentNodeOriginal/(@name | @id)
    let $idOfParentNodeRefined := $parentNodeRefined/(@name | @id)

    (: use local-name instead of name to circumvent problems with prefix names :)
    return $idOfStateOriginal = $idOfStateRefined and ($idOfParentNodeOriginal = $idOfParentNodeRefined or $parentNodeRefined/local-name() = 'parallel')
};

(: checks if all states in U are available in U' and if they have the same ancestor (substates!) :)
declare function scc:isEveryOriginalStateInRefined($originalStates, $refinedStates) as xs:boolean {
    let $allStatesFromOriginalAreOk :=
        every $originalState in $originalStates satisfies
        for $refinedState in $refinedStates
        return if (scc:isOriginalStateEqualToStateFromRefined($originalState, $refinedState)) then(
            true()
        ) else ()

    return  $allStatesFromOriginalAreOk
};


declare function scc:compareTransitions($origTransition as element(),
        $newTransition as element()
) as xs:boolean {
(:
    check if $origTransition is the 'same' as $newTransition
    rules:
        1. $newTransition may have a more specialized source state.
        2. $newTransition may have a more specialized target state.
            - If both have no target, then target check is ok
            - if source has no target, newTransition may have a target which is stateOrSubstate of source
        3. condition may be added to $newTransition (if $origTransition had no cond). If no condition, every cond can be introduced
        4. conditions in $newTransition may be specialized, by adding terms with 'AND'
        5. dot notation of events. If no event, every event can be introduced
:)

    let $origSource := fn:string(sc:getSourceState($origTransition)/@id)
    let $origTarget := fn:string($origTransition/@target)
    let $origEvent := fn:string($origTransition/@event)

    let $scxml := $newTransition/ancestor::sc:scxml[1]
    let $origSourceAndSubstates := scc:getStateAndSubstates($scxml, $origSource)
    let $origTargetAndSubstates := scc:getStateAndSubstates($scxml, $origTarget)

    return
        if (
        (: 1. :)(not(sc:getSourceState($origTransition)/@id or sc:getSourceState($newTransition)/@id) or functx:is-value-in-sequence(fn:string(sc:getSourceState($newTransition)/@id), $origSourceAndSubstates)) and
                (: 2. :)(not($origTransition/@target or $newTransition/@target)
                or functx:is-value-in-sequence(fn:string($newTransition/@target), $origTargetAndSubstates)
                or (not($origTransition/@target) and functx:is-value-in-sequence($newTransition/@target, $origSourceAndSubstates))) and
                (: 3&4:)(not($origTransition/@cond) or scc:compareConditions($origTransition/@cond, $newTransition/@cond)) and
                (: 5. :)(not($origEvent) or scc:compareEvents($origEvent, fn:string($newTransition/@event)))
        ) then
            true()
        else
            false()
};

declare function scc:getStateAndSubstates($scxml as element(),
        $state as xs:string
) as xs:string* {
    $scxml//(sc:state | sc:parallel | sc:final)[@id = $state]/(descendant-or-self::sc:state | descendant-or-self::sc:parallel | descendant-or-self::sc:final)/fn:string(@id)
};

declare function scc:compareConditions($origCond as xs:string,
        $newCond as xs:string
) as xs:boolean {
    (fn:compare($origCond, $newCond) = 0) or
            ((fn:compare($origCond, fn:substring($newCond, 1, fn:string-length($origCond))) = 0) and
                    (fn:compare(' and ', fn:substring($newCond, fn:string-length($origCond) + 1, 5)) = 0))
};

declare function scc:compareEvents($origEvent as xs:string,
        $newEvent as xs:string
) as xs:boolean {
    (fn:compare($origEvent, $newEvent) = 0) or
            ((fn:compare($origEvent, fn:substring($newEvent, 1, fn:string-length($origEvent))) = 0) and
                    (fn:compare('.', fn:substring($newEvent, fn:string-length($origEvent) + 1, 1)) = 0))
};

