(:~

 : --------------------------------
 : MBAse: An MBA database in XQuery
 : --------------------------------
  
 : Copyright (C) 2014, 2015 Christoph Schütz
   
 : This program is free software; you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation; either version 2 of the License, or
 : (at your option) any later version.
 
 : This program is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 : GNU General Public License for more details.
 
 : You should have received a copy of the GNU General Public License along
 : with this program; if not, write to the Free Software Foundation, Inc.,
 : 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
  
 : @author Christoph Schütz
 : @author Michael Weichselbaumer
 :)
module namespace reflection='http://www.dke.jku.at/MBA/Reflection';

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'mba.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'scxml.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx.xqm';
import module namespace scc = "http://www.w3.org/2005/07/scxml/consistency/" at 'scxml_consistency.xqm';

declare updating function reflection:setActive($mba  as element(),
                                               $name as xs:string) {
  ()
};


declare function reflection:getRefinedState($state as element(), $subState as element()) as element()* {
  let $mba := $state/ancestor::mba:mba

    return if (not(mba:getDescendants($mba))) then (
      let $originalScxml := $state/ancestor::sc:scxml

      let $refinedScxml := copy $c := $originalScxml modify (
        let $stateCopy := $c//sc:state[@id=$state/@id/data()]
        return insert node $subState into $stateCopy
      ) return $c

      return if (scc:isBehaviorConsistentSpecialization($originalScxml, $refinedScxml)) then (
          $refinedScxml//sc:state[@id=$state/@id/data()]
      ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                        'RefineStateConsistencyCheck'),
                        'State cannot be refined because this would result in behavior consistency violation')
      )
    ) else (
      error(QName('http://www.dke.jku.at/MBA/err',
              'RefineStateDescendantCheck'),
              concat('State cannot be refined because MBA ', $mba/@name/data(), ' has already descendants'))
    )
};

declare updating function reflection:refineState($state as element(), $subState as element()) {
    let $refinedState := reflection:getRefinedState($state, $subState)
    return replace node $state with $refinedState
};


declare function reflection:getParallelRegionExtension($state as element(), $parallelState as element()+, $optionalNodes as element()?) as element()* {
    let $mba := $state/ancestor::mba:mba

    return if (not(mba:getDescendants($mba))) then (
        let $originalScxml := $state/ancestor::sc:scxml

        let $refinedScxml := copy $c := $originalScxml modify (
            let $stateCopy := $c//sc:state[@id=$state/@id/data()]
            let $newParallelNode := <sc:parallel>
                {$optionalNodes}
                {$stateCopy}
                {$parallelState}
            </sc:parallel>
            return replace node $stateCopy with $newParallelNode

        ) return $c

        return if (scc:isBehaviorConsistentSpecialization($originalScxml, $refinedScxml)) then (
            $refinedScxml//sc:state[@id=$state/@id/data()]/..
        ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'ExtendWithParallelRegionConsistencyCheck'),
                    'Parallel region cannot be introduced because this would result in behavior consistency violation')
        )
    ) else (
        error(QName('http://www.dke.jku.at/MBA/err',
                'ExtendWithParallelRegionDescendantCheck'),
                concat('Parallel region cannot be introduced because MBA ', $mba/@name/data(), ' has already descendants'))
    )
};

declare updating function reflection:extendWithParallelRegion($state as element(), $parallelState as element(), $optionalNodes as element()?) {
    let $parallelRegionNode := reflection:getParallelRegionExtension($state, $parallelState, $optionalNodes)
    return replace node $state with $parallelRegionNode
};

declare function reflection:getTransitionWithRefinedPreCondition($transition as element(), $condition as xs:string) as element()* {
    let $mba := $transition/ancestor::mba:mba

    return if (not(mba:getDescendants($mba))) then (
        let $originalScxml := $transition/ancestor::sc:scxml

        let $transitionSourceState := sc:getSourceState($transition)
        let $indexOfTransition := functx:index-of-node($transitionSourceState//sc:transition, $transition)

        let $refinedScxml := copy $c := $originalScxml modify (
            let $stateCopy := $c//sc:state[@id = $transitionSourceState/@id/data()]
            let $transitionCopy := $stateCopy//sc:transition[$indexOfTransition]
            let $conditionCopy := $transitionCopy/@cond

            return if (fn:empty($conditionCopy)) then (
                replace node $transitionCopy with functx:add-attributes($transitionCopy, fn:QName('', 'cond'), $condition)
            ) else (
                replace node $transitionCopy with functx:add-or-update-attributes($transitionCopy, fn:QName('', 'cond'), ($conditionCopy || " and " || $condition))
            )
        ) return $c

        return if (scc:isBehaviorConsistentSpecialization($originalScxml, $refinedScxml)) then (
            $refinedScxml//sc:state[@id = $transitionSourceState/@id]//sc:transition[$indexOfTransition]
        ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'RefineTransitionWithPreConditionConsistencyCheck'),
                    concat('Transition cannot be refined with precondition ', $condition, ' because this would result in behavior consistency violation'))
        )
    ) else (
        error(QName('http://www.dke.jku.at/MBA/err',
                'RefineTransitionPreConditionCheck'),
                concat('Transition cannot be refined with condition ', $condition, ' because MBA ', $mba/@name/data(), ' has already descendants'))
    )
};

declare updating function reflection:refinePreCondition($transition as element(), $condition as xs:string) {
    let  $refinedTransition := reflection:getTransitionWithRefinedPreCondition($transition, $condition)
    return replace node $transition with $refinedTransition
};

declare function reflection:getTransitionWithRefinendEvents($transition as element(), $event as xs:string) as element()* {
    let $mba := $transition/ancestor::mba:mba

    return if (not(mba:getDescendants($mba))) then (
        let $originalScxml := $transition/ancestor::sc:scxml

        let $transitionSourceState := sc:getSourceState($transition)
        let $indexOfTransition := functx:index-of-node($transitionSourceState//sc:transition, $transition)

        let $refinedScxml := copy $c := $originalScxml modify (
            let $stateCopy := $c//sc:state[@id = $transitionSourceState/@id/data()]
            let $transitionCopy := $stateCopy//sc:transition[$indexOfTransition]

            return replace node $transitionCopy with functx:add-or-update-attributes($transitionCopy, fn:QName('', 'event'), ($event))
        ) return $c

        return if (scc:isBehaviorConsistentSpecialization($originalScxml, $refinedScxml)) then (
            $refinedScxml//sc:state[@id = $transitionSourceState/@id]//sc:transition[$indexOfTransition]
        ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                    'RefineTransitionWithEventConsistencyCheck'),
                    concat('Transition cannot be refined with event ', $event, ' because this would result in behavior consistency violation'))
        )
    ) else (
        error(QName('http://www.dke.jku.at/MBA/err',
                'RefineTransitionEventCheck'),
                concat('Transition cannot be refined with event ', $event, ' because MBA ', $mba/@name/data(), ' has already descendants'))
    )
};

declare updating function reflection:refineEvent($transition as element(), $event as xs:string) {
    let  $refinedTransition := reflection:getTransitionWithRefinendEvents($transition, $event)
    return replace node $transition with $refinedTransition
};