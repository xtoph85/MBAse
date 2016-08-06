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

declare function scc:getStateAndSubstates($scxml as element(),
        $state as xs:string
) as xs:string* {
    $scxml//(sc:state | sc:parallel | sc:final)[@id = $state]/(descendant-or-self::sc:state | descendant-or-self::sc:parallel | descendant-or-self::sc:final)/fn:string(@id)
};

(: this function returns all states (including their substates) of an original model from its' refined model :)
declare function scc:getAllOriginalStatesFromRefined($scxmlOriginal, $scxmlRefined) as element()* {
    let $statesOriginal := scc:getAllStates($scxmlOriginal)
    let $statesRefined := scc:getAllStates($scxmlRefined)

    let $refinedStatesFromOriginal :=
        for $refinedState in $statesRefined
        where functx:is-value-in-sequence($refinedState/@id, $statesOriginal/@id)
        return $refinedState

    return $refinedStatesFromOriginal
};

declare function scc:getAllRelevantStateIdsRelevantToOriginalFromRefined($originalStates) {
    for $state in $originalStates
        return ($state/@id/data(), sc:getChildStates($state)/@id/data())
};

declare function scc:getAllRefinedTransitionsWithRelevantTargetState($scxmlOriginal, $scxmlRefined) as element()* {
    let $refinedStatesFromOriginal := scc:getAllOriginalStatesFromRefined($scxmlOriginal, $scxmlRefined)

    (: return all transitions with relevant or no target state :)
    let $allStateIdsRelevantToOriginalModel := scc:getAllRelevantStateIdsRelevantToOriginalFromRefined($refinedStatesFromOriginal)
    let $refinedTransitionsWithRelevantTargetState :=
        for $transition in scc:getAllStates($scxmlRefined)//sc:transition
        where functx:is-value-in-sequence($transition/@target/data(), $allStateIdsRelevantToOriginalModel) or not($transition/@target)
        return $transition

    return $refinedTransitionsWithRelevantTargetState
};

declare function scc:getAllRefinedTransitionsWithRelevantSourceAndTargetState($scxmlOriginal, $scxmlRefined) as element()* {
    (: get rid of transitions that have source AND target state (or no target state) that is not available in original model  :)
    let $refinedTransitionsWithRelevantSourceAndTargetState :=
        for $transition in scc:getAllRefinedTransitionsWithRelevantTargetState($scxmlOriginal, $scxmlRefined)
        return if ((not(functx:is-value-in-sequence($transition/../@id/data(), scc:getAllStates($scxmlOriginal)/@id/data())) and
                not(functx:is-value-in-sequence($transition/@target/data(), scc:getAllStates($scxmlOriginal)/@id/data()))) and
                not(fn:empty($transition/@target))
        ) then (
                ()
            ) else (
                $transition
            )
    return $refinedTransitionsWithRelevantSourceAndTargetState
};

(: this functions check if all transitions from U are available in U' and no new transitions between states in U are added in U' :)
declare function scc:isEveryOriginalTransitionInRefined($scxmlOriginal, $scxmlRefined) as xs:boolean {
    let $statesOriginal := scc:getAllStates($scxmlOriginal)
    let $originalTransitions := $statesOriginal//sc:transition
    let $refinedTransitionsToCheck := scc:getAllRefinedTransitionsWithRelevantSourceAndTargetState($scxmlOriginal, $scxmlRefined)

    (: if number of refinedTransitionsToCheck is greater than number of originalTransitions, a new transition between existing states has been introduced
        else if number is smaller, a transition has been removed. both is not allowed :)
    return if (fn:count($refinedTransitionsToCheck) = fn:count($originalTransitions)) then (
        let $noOfMatchingTransitionsList :=
            for $orginalTransition in $originalTransitions
            let $matchingTransitions :=
                for $refinedTransition in $refinedTransitionsToCheck
                return if (scc:compareTransitions($orginalTransition, $refinedTransition)) then (
                    true()
                ) else ()
            return fn:count($matchingTransitions)

        return every $noOfMatchingTransitions in $noOfMatchingTransitionsList satisfies ($noOfMatchingTransitions = 1)
    ) else (
        if (fn:count($refinedTransitionsToCheck) > fn:count($originalTransitions)) then (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'BehaviorConsistencyTransitionCheck'),
                    'Illegal transition between states of original model introduced in refined model')
        ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'BehaviorConsistencyTransitionCheck'),
                    'Required transition of original model removed in refined model')
            )
    )
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
        return if (scc:isOriginalStateEqualToStateFromRefined($originalState, $refinedState)) then (
            true()
        ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'BehaviorConsistencyStateCheck'),
                    concat('Refined model is missing state or substate with id "', $originalState/@id/data(), '"'))
        )

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
                (: 3&4:)(not($origTransition/@cond) or (($newTransition/@cond) and scc:compareConditions($origTransition/@cond, $newTransition/@cond))) and
                (: 5. :)(not($origEvent) or scc:compareEvents($origEvent, fn:string($newTransition/@event)))
        ) then
            true()
        else
            false()
};

declare function scc:compareConditions($origCond as xs:string, $newCond as xs:string) as xs:boolean {
    (: original clause is not modified :)
    (fn:compare($origCond, $newCond) = 0) or
            (: 'and' is added after original clause:)
            ((fn:compare($origCond, fn:substring($newCond, 1, fn:string-length($origCond))) = 0) and
                    (fn:compare(' and ', fn:substring($newCond, fn:string-length($origCond) + 1, 5)) = 0)) or
            (: 'and' is added before original clause :)
            ((fn:compare($origCond, fn:substring($newCond, fn:string-length($newCond) - fn:string-length($origCond) + 1, fn:string-length($newCond))) = 0)) and
                    (fn:compare(' and', fn:substring($newCond, fn:string-length($newCond) - fn:string-length($origCond) - 4, 4)) = 0)

};

declare function scc:compareEvents($origEvent as xs:string,
        $newEvent as xs:string
) as xs:boolean {
    (fn:compare($origEvent, $newEvent) = 0) or
            ((fn:compare($origEvent, fn:substring($newEvent, 1, fn:string-length($origEvent))) = 0) and
                    (fn:compare('.', fn:substring($newEvent, fn:string-length($origEvent) + 1, 1)) = 0))
};

