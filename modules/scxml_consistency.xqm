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
