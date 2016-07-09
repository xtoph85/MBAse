(:~

 : --------------------------------
 : SCXML-XQ: An SCXML interpreter in XQuery
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
 
 : This module provides the functionality for working with SCXML documents,
 : consisting of functions for the interpretation and manipulation 
 : of SCXML documents.
 
 : The SCXML interpreter depends on the external FunctX library, which is
 : distributed by the original developers under GNU LGPL. The FunctX library
 : is included in the repository.
 
 : @author Christoph Schütz
 :)
module namespace sc = 'http://www.w3.org/2005/07/scxml';
import module namespace scx='http://www.w3.org/2005/07/scxml/extension/' at 'scxml_extension.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx.xqm';

(:~
 : 
 :)
declare function sc:matchesEventDescriptors($eventName        as xs:string,
                                            $eventDescriptors as xs:string*)
    as xs:boolean {
  some $descriptor in $eventDescriptors satisfies
    fn:matches($eventName, '^' || $descriptor)
};

(:~
 : Selects the data models that are valid in the current configuration.
 : 
 : Note: The configuration must consist of the original nodes (not copies) from
 :       the SCXML document.
 : Note: All states in the configuration are assumed to have been taken from the
 :       same SCXML document.
 : 
 : @param $configuration the list of active nodes
 : 
 : @return a list of data models; original nodes, not copies.
 :)
declare function sc:selectDataModels($configuration as element()*) 
    as element()* {
  let $global := 
    $configuration[1]/ancestor::sc:scxml/sc:datamodel
  
  let $local := for $s in $configuration return $s/sc:datamodel
  
  return ($global, $local)
};

(:~
 : 
 :)
declare updating function sc:assign($dataModels as element()*,
                                    $location   as xs:string,
                                    $expression as xs:string?,
                                    $type       as xs:string?,
                                    $attribute  as xs:string?,
                                    $nodelist   as node()*) {  
  let $dataBindings :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return map:entry($data/@id, $data)
  
  let $declare :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return 'declare variable $' || $data/@id || ' external; '
  
  let $declareNodeList :=
    'declare variable $nodelist external; '
  
  let $expression :=
    if (not($expression) or $expression = '') 
    then '() '
    else $expression
  
  return
    xquery:update(
      scx:importModules() ||
      fn:string-join($declare) ||
      $declareNodeList ||
      scx:builtInFunctionDeclarations() ||
      'let $locations := ' || $location || ' ' || (
      if ($expression) then
        'let $newValues := ' || $expression || ' '
      else 
        'let $newValues := $nodelist ' 
      ) ||
      'return ' || (
        if ($type = 'firstchild') then (
          'for $l in $locations ' ||
            'return insert node $newValues as first into $l '
        ) else if ($type = 'lastchild') then (
          'for $l in $locations ' ||
            'return insert node $newValues as last into $l '
        ) else if ($type = 'previoussibling') then (
          'for $l in $locations ' ||
            'return insert node $newValues before $l '
        ) else if ($type = 'nextsibling') then (
          'for $l in $locations ' ||
            'return insert node $newValues after $l '
        ) else if ($type = 'replace') then (
          'for $l in $locations ' ||
            'return replace node $l with $newValues '
        ) else if ($type = 'delete') then (
          'for $l in $locations ' ||
            'return delete node $l '
        ) else if ($type = 'addattribute') then (
          'for $l in $locations ' ||
            'return insert node attribute ' || $attribute || ' {$newValues} into $l '
        ) else ( 
          'for $l in $locations ' ||
            'let $empty   := copy $c := $l modify(delete nodes $c/*) return $c ' ||
            'let $emptier := copy $c := $empty modify(replace value of node $c with "") return $c ' ||
            'let $newNode := copy $c := $emptier modify(insert nodes $newValues into $c) return $c ' ||
            'return replace node $l with $newNode '
        )
      ), map:merge(($dataBindings, map:entry('nodelist', $nodelist)))
    )
};

declare function sc:selectEventlessTransitions($configuration as element()*,
                                               $dataModels    as element()*) 
    as element()* {
      
  let $atomicStates :=
    $configuration[sc:isAtomicState(.)]
    
  let $dataBindings :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return map:entry($data/@id, $data)
  
  let $declare :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return 
          'declare variable $' || $data/@id || ' external; '
      
  let $enabledTransitions :=
    for $state in $atomicStates 
      let $transitions :=  
        for $s in ($state, sc:getProperAncestors($state))
          let $transitions :=
            $s/sc:transition[(not(@event) or @event = '') and (
                               not(@cond) or @cond = '' or
                               xquery:eval(
                                 scx:importModules() ||
                                 fn:string-join($declare) || 
                                 scx:builtInFunctionDeclarations() ||
                                 'return ' || @cond, 
                                 map:merge($dataBindings)
                               )
                             )]
          return $transitions[1]
    return $transitions
  
  return sc:removeConflictingTransitions($configuration, $enabledTransitions)  
};

declare function sc:selectTransitions($configuration as element()*,
                                      $dataModels as element()*,
                                      $event as xs:string) as element()* {
  
  let $atomicStates :=
    $configuration[sc:isAtomicState(.)]
  
  let $dataBindings :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return map:entry($data/@id, $data)
  
  let $declare :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return 
          'declare variable $' || $data/@id || ' external; '
        
  let $enabledTransitions :=
    for $state in $atomicStates 
      for $s in ($state, sc:getProperAncestors($state))
        let $transitions :=
          $s/sc:transition[sc:matchesEventDescriptors(
                             $event,
                             fn:tokenize(@event, '\s')
                           ) and (
                             not(@cond) or
                             xquery:eval(
                               scx:importModules() ||
                               fn:string-join($declare) || 
                               scx:builtInFunctionDeclarations() ||
                               'return ' || @cond, 
                               map:merge($dataBindings)
                             )
                           )]
      return $transitions[1]
  
  return sc:removeConflictingTransitions($configuration, $enabledTransitions)
};

declare function sc:removeConflictingTransitions($configuration as element()*,
                                                 $transitions as element()*)
    as element()*{
  let $enabledTransitions := functx:distinct-nodes($transitions)
  
  let $filteredTransitions := fn:fold-left(?, (),
    function($filteredTransitions, $t1) {
      let $exitSetT1 := sc:computeExitSet($configuration, ($t1))
      let $t2 := ($filteredTransitions[
        some $s in $exitSetT1 satisfies 
        functx:index-of-node(sc:computeExitSet($configuration, .), $s)
      ])[1]
      let $filteredTransitions :=
        if ($t2) then (
          if (sc:isDescendant(sc:getSourceState($t1), 
                              sc:getSourceState($t2))) then (
            (fn:remove($filteredTransitions, 
                       functx:index-of-node($filteredTransitions, $t2)), $t1)
          ) 
          else ()
        )        
        else ($filteredTransitions, $t1)
      
      return $filteredTransitions
    }
  )
  
  return $filteredTransitions($enabledTransitions)
};

declare function sc:computeExitSet($configuration as element()*,
                                   $transitions as element()*) as element()*{
  let $statesToExit := 
    for $t in $transitions 
      let $domain := sc:getTransitionDomain($t)
      for $s in $configuration
        return if (sc:isDescendant($s, $domain)) then $s else ()
  
  return $statesToExit
};

declare function sc:computeEntrySet($transitions as element()*) as element()* {
  if (fn:empty($transitions)) then ()
  else
    let $statesToEnterStart := 
      for $t in $transitions
        return sc:getTargetStates($t)
    
    let $stateLists :=
      map:merge((
        map:entry('statesToEnter', ()),
        map:entry('statesForDefaultEntry', ())
      ))
      
    let $addDescendants := fn:fold-left(?, $stateLists,
      function($stateListsResult, $s) {
        let $statesToEnter := 
          map:get($stateListsResult, 'statesToEnter')
        let $statesForDefaultEntry := 
          map:get($stateListsResult, 'statesForDefaultEntry')
          
        let $f := function($statesToEnter, $statesForDefaultEntry) { 
          map:merge((
            map:entry('statesToEnter', $statesToEnter),
            map:entry('statesForDefaultEntry', $statesForDefaultEntry)
          ))
        }
        
        return
          sc:addDescendantStatesToEnter($s, $statesToEnter, $statesForDefaultEntry, $f)
      }
    )
    
    let $stateLists := $addDescendants($statesToEnterStart)
   
    let $stateLists := 
      (
       for $t in $transitions
         let $ancestor := sc:getTransitionDomain($t)
         let $addAncestors := fn:fold-left(?, $stateLists,
           function($stateListsResult, $s) {
             let $statesToEnter := 
               map:get($stateListsResult, 'statesToEnter')
             let $statesForDefaultEntry := 
               map:get($stateListsResult, 'statesForDefaultEntry')
              
             let $f := function($statesToEnter, $statesForDefaultEntry) { 
               map:merge((
                 map:entry('statesToEnter', $statesToEnter),
                 map:entry('statesForDefaultEntry', $statesForDefaultEntry)
               ))
             }
             
             return
               sc:addAncestorStatesToEnter($s, $ancestor, $statesToEnter, $statesForDefaultEntry, $f)
           }
         )
         
         for $s in sc:getTargetStates($t)
           return $addAncestors($s)
      )
    
    let $statesToEnter := 
      if (not (fn:empty($stateLists))) then map:get($stateLists, 'statesToEnter')
      else ()
    
    return $statesToEnter
};


declare function sc:addDescendantStatesToEnter($state as element()) as item() {
  (: TODO: history states :)
  
  let $f := function($statesToEnter, $statesForDefaultEntry) { 
    map:merge((
      map:entry('statesToEnter', $statesToEnter),
      map:entry('statesForDefaultEntry', $statesForDefaultEntry)
    ))
  }
  
  return sc:addDescendantStatesToEnter($state, (), (), $f)
};

declare function sc:addDescendantStatesToEnter($states                as element()*,
                                               $statesToEnter         as element()*,
                                               $statesForDefaultEntry as element()*,
                                               $cont) as item() {
  (: TODO: history states :)
  
  let $results :=
    if (fn:empty($states)) then $cont($statesToEnter, $statesForDefaultEntry)
    else if (sc:isAtomicState($states[1])) then
      sc:addDescendantStatesToEnter(
        $states[position() > 1], ($statesToEnter, $states[1]), $statesForDefaultEntry, $cont
      )
    else if (sc:isCompoundState($states[1])) then
       let $initialStates := sc:getInitialStates($states[1])
       return sc:addDescendantStatesToEnter(
         $initialStates[1], 
         ($statesToEnter, $states[1]), 
         ($statesForDefaultEntry, $states[1]),
         function($statesToEnter1, $statesForDefaultEntry1) {
           sc:addAncestorStatesToEnter(
             $initialStates[1],
             $states[1],
             $statesToEnter1,
             $statesForDefaultEntry1,
             function($statesToEnter2, $statesForDefaultEntry2) {
               sc:addDescendantStatesToEnter(
                 $initialStates[position() > 1], 
                 $statesToEnter2,
                 $statesForDefaultEntry2,
                 $cont
               )
             }
           )
         }
       )
    else if (sc:isParallelState($states[1])) then
       let $childStates := sc:getChildStates($states[1])
       let $childStatesNotAdded := 
         $childStates[not (some $s in $statesToEnter satisfies sc:isDescendant($s, .))]
         
       return sc:addDescendantStatesToEnter(
         $childStatesNotAdded[1], 
         ($statesToEnter, $states[1]), 
         $statesForDefaultEntry,
         function($statesToEnter1, $statesForDefaultEntry1) {
           sc:addDescendantStatesToEnter(
             $childStatesNotAdded[position() > 1], 
             $statesToEnter1,
             $statesForDefaultEntry1,
             function($statesToEnter2, $statesForDefaultEntry2) {
               sc:addDescendantStatesToEnter($states[position() > 1],
                                             $statesToEnter2,
                                             $statesForDefaultEntry2,
                                             $cont)
             }
           )
         }
       )
    else ()
  
  return $results
};

declare function sc:addAncestorStatesToEnter($state as element(),
                                             $ancestor as element()) as item() {
  let $f := function($statesToEnter, $statesForDefaultEntry) { 
    map:merge((
      map:entry('statesToEnter', $statesToEnter),
      map:entry('statesForDefaultEntry', $statesForDefaultEntry)
    ))
  }
  
  return sc:addAncestorStatesToEnter($state, $ancestor, (), (), $f)
};

declare function sc:addAncestorStatesToEnter($states as element()*,
                                             $ancestor as element(),
                                             $statesToEnter as element()*,
                                             $statesForDefaultEntry as element()*,
                                             $cont) as item() {
  let $properAncestors :=
    for $s in $states return sc:getProperAncestors($s, $ancestor)
  
  let $results :=
    if (fn:empty($properAncestors)) then $cont($statesToEnter, $statesForDefaultEntry)
    else sc:foldAncestorStatesToEnter ($properAncestors,
                                       $statesToEnter,
                                       $statesForDefaultEntry,
                                       $cont)
  
  return $results
};

declare function sc:foldAncestorStatesToEnter($states as element()*,
                                              $statesToEnter as element()*,
                                              $statesForDefaultEntry as element()*,
                                              $cont) as item() {
  let $results := 
    if (fn:empty($states)) then  $cont($statesToEnter, $statesForDefaultEntry)
    else if (sc:isParallelState($states[1])) then
      let $childStates := sc:getChildStates($states[1])
      let $childStatesNotAdded := 
        $childStates[not (some $s in $statesToEnter satisfies sc:isDescendant($s, .))]
         
      return sc:addDescendantStatesToEnter(
        $childStatesNotAdded[1], 
        ($statesToEnter, $states[1]), 
        $statesForDefaultEntry,
        function($statesToEnter1, $statesForDefaultEntry1) {
          sc:addDescendantStatesToEnter(
            $childStatesNotAdded[position() > 1], 
            $statesToEnter1,
            $statesForDefaultEntry1,
            function($statesToEnter2, $statesForDefaultEntry2) {
              sc:foldAncestorStatesToEnter($states[position() > 1],
                                           $statesToEnter2,
                                           $statesForDefaultEntry2,
                                           $cont)
            }
          )
        }
      )
    else sc:foldAncestorStatesToEnter(
      $states[position() > 1],
      ($statesToEnter, $states[1]), 
      $statesForDefaultEntry, 
      $cont
    )
  
  return $results
};

declare function sc:getInitialStates($state) as element()* {
  if ($state/@initial) then 
    for $s in fn:tokenize($state/@initial, '\s')
      return $state//*[@id = $s]
  else (
    for $transition in $state/sc:initial/sc:transition
      return sc:getEffectiveTargetStates($transition)
  )
};


declare function sc:getAllStates($scxml) as element()* {
  $scxml//(sc:state | sc:parallel | sc:final)
};

(: this method checks if a scxml-state is equal to another scxml-state from a refined scxml-model :)
declare function sc:isOriginalStateEqualToStateFromRefined($originalState, $refinedState) as xs:boolean {
  let $idOfStateOriginal := $originalState/@id
  let $idOfStateRefined := $refinedState/@id

  let $idOfParentNodeOriginal :=  $originalState/../(@name | @id)
  let $idOfParentNodeRefined := $refinedState/../(@name | id)

  return $idOfStateOriginal = $idOfStateRefined and $idOfParentNodeOriginal = $idOfParentNodeRefined
};

declare function sc:isCompoundState($state as element()) as xs:boolean {
  ( fn:exists($state/sc:state) or
    fn:exists($state/sc:parallel) ) and
  fn:exists($state/self::sc:state)
};

declare function sc:isAtomicState($state as element()) as xs:boolean {
  empty($state/sc:state) and
  empty($state/sc:parallel)
};

declare function sc:isParallelState($state as element()) as xs:boolean {  
  fn:exists($state/self::sc:parallel)
};

declare function sc:getChildStates($state as element()) as element()* {
  $state/*[self::sc:state or self::sc:parallel]
};

declare function sc:getDescendantStates($state as element()) as element()* {
  $state//*[self::sc:state or self::sc:parallel]
};

declare function sc:getTargetStates($transition as element()) as element()* {
  if (not($transition/@target)) then () 
  else 
    for $state in fn:tokenize($transition/@target, '\s')
      return $transition/ancestor::sc:scxml//*[@id = $state]
};

declare function sc:getEffectiveTargetStates($transition as element()) as element()* {
  (: TODO: history states :)
  
   sc:getTargetStates($transition)
};

declare function sc:getSourceState($transition as element()) as element() {  
  $transition/..
};

declare function sc:isInternalTransition($transition as element()) as xs:boolean {  
  fn:exists($transition/@type='internal')
};

declare function sc:getTransitionDomain($transition as element()) as element() {
  let $targetStates := sc:getTargetStates($transition)
  let $sourceState :=  sc:getSourceState($transition) 
  
  return
    if (empty($targetStates)) then $sourceState 
    else if (sc:isInternalTransition($transition) and
             sc:isCompoundState($sourceState) and 
             (every $s in $targetStates satisfies sc:isDescendant($s, $sourceState)))
      then $sourceState
    else sc:findLCCA(($sourceState, $targetStates))
};


declare function sc:findLCCA($states as element()*) as element() {
  let $ancestorsOfHead := 
    sc:getProperAncestors(fn:head($states))
  
  let $tail := fn:tail($states)
  
  let $lcca := 
    (for $anc in $ancestorsOfHead 
       return
         if (every $s in $tail satisfies sc:isDescendant($s, $anc)) then 
           $anc else ( (: do nothing :) )
    )[1]
  
  return $lcca
};

declare function sc:isDescendant($state1 as element(),
                                 $state2 as element()) as xs:boolean {
  some $n in $state2//descendant::* satisfies $n is $state1
};

declare function sc:getProperAncestors($state as element()) as element()* {
  fn:reverse($state/ancestor::*)
};

declare function sc:getProperAncestors($state as element(),
                                       $upTo  as element()) as element()* {
  fn:reverse($state/ancestor::*[$upTo << .])
};

declare function sc:eval($expr       as xs:string,
                         $dataModels as element()*) {
  let $dataBindings :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return map:entry($data/@id, $data)
  
  let $declare :=
    for $dataModel in $dataModels
      for $data in $dataModel/sc:data
        return 'declare variable $' || $data/@id || ' external; '
      
  return xquery:eval(fn:string-join($declare) || 
                     $expr, 
                     map:merge($dataBindings))
};

declare function sc:isSubDescriptorOrEqual($subDescriptor   as xs:string,
                                           $superDescriptor as xs:string) 
    as xs:boolean {
  fn:matches($subDescriptor, '^' || $superDescriptor)
};

(:~
 : 
 :)
declare function sc:getSpecializedTransitions($transition as element(),
                                              $scxml      as element())
    as element()* {
  let $originalState := $transition/..
  
  let $scxmlState := 
    typeswitch($originalState)
      case element(sc:scxml) return $scxml
      case element(sc:state) return $scxml//sc:state[@id = $originalState/@id]
      case element(sc:parallel) 
        return $scxml//sc:parallel[@id = $originalState/@id]
      default return ()
  
  let $originalTargetStates :=
    sc:getTargetStates($transition)
    
  let $scxmlOriginalTargetStates :=
    for $s in $originalTargetStates return
      typeswitch($s)
        case element(sc:state) return $scxml//sc:state[@id = $s/@id]
        case element(sc:parallel) 
          return $scxml//sc:parallel[@id = $s/@id]
        default return ()
  
      
      
  let $scxmlTransitions :=
    $scxmlState//sc:transition[
      ( (not(@event) and not($transition/@event)) or 
        (@event = '' and $transition/@event = '') or 
        sc:isSubDescriptorOrEqual(@event, $transition/@event) ) and
        
      ( (not(@cond) and not($transition/@cond)) or 
        (@cond = '' and $transition/@cond = '') or 
        not($transition/@cond) or $transition/@cond = '' or
        @cond = $transition/@cond or
        fn:matches(@cond, '^' || 
                   functx:escape-for-regex($transition/@cond || ' and')) or
        fn:matches(@cond, 
                   functx:escape-for-regex(' and ' || $transition/@cond) || '$') 
      ) and
      
      ( (not(@target) and not($transition/@target)) or 
        (@target = '' and $transition/@target = '') or 
        (
          let $newTargets := fn:tokenize(@target, '\s')
          return
          every $target in $scxmlOriginalTargetStates satisfies (
            some $newTarget in $newTargets satisfies 
              $target/@id = $newTarget or
              $target//*/@id = $newTarget
          )
        ) 
      ) and
        
      ( (not(@type) and not($transition/@type)) or 
        (@type = '' and $transition/@type = '') or 
        @type = $transition/@type )
    ]
  
  return $scxmlTransitions
};