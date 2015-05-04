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
 :)
module namespace sync='http://www.dke.jku.at/MBA/Synchronization';

import module namespace mba = 'http://www.dke.jku.at/MBA';
import module namespace sc = 'http://www.w3.org/2005/07/scxml';
import module namespace functx = 'http://www.functx.com';

declare function sync:eval($expr       as xs:string,
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

declare function sync:everyDescendantAtLevelIsInState($mba     as element(),
                                                      $level   as xs:string,
                                                      $stateId as xs:string) 
    as xs:boolean {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
    return every $descendant in $descendants satisfies
      mba:isInState($descendant, $stateId)
};

declare function sync:someDescendantAtLevelIsInState($mba     as element(),
                                                     $level   as xs:string,
                                                     $stateId as xs:string) 
    as xs:boolean {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
    return some $descendant in $descendants satisfies
      mba:isInState($descendant, $stateId)
};

declare function sync:everyDescendantAtLevelSatisfies
    ($mba   as element(),
     $level as xs:string,
     $cond  as xs:string) as xs:boolean {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
  
  return every $descendant in $descendants satisfies
    let $dataModels :=
      sc:selectDataModels(mba:getConfiguration($descendant))
    return sc:eval($cond, $dataModels)
};

declare function sync:someDescendantAtLevelSatisfies
    ($mba   as element(),
     $level as xs:string,
     $cond  as xs:string) as xs:boolean {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
    return some $descendant in $descendants satisfies
      let $dataModels :=
        sc:selectDataModels(mba:getConfiguration($descendant))
  
  return sc:eval($cond, $dataModels)
};

declare function sync:ancestorAtLevelSatisfies
    ($mba   as element(),
     $level as xs:string,
     $cond  as xs:string) as xs:boolean {
  let $ancestor   := mba:getAncestorAtLevel($mba, $level)
  let $dataModels := sc:selectDataModels(mba:getConfiguration($ancestor))
  
  return sync:eval($cond, $dataModels)
};

declare function sync:ancestorAtLevelIsInState($mba     as element(),
                                               $level   as xs:string,
                                               $stateId as xs:string) 
    as xs:boolean {
  let $ancestor := mba:getAncestorAtLevel($mba, $level)
  
  return mba:isInState($ancestor, $stateId)
};

declare updating function sync:sendAncestor($mba     as element(),
                                            $eventId as xs:string,
                                            $level   as xs:string,
                                            $param   as element()*,
                                            $content as element()?) {
  let $ancestor := mba:getAncestorAtLevel($mba, $level)
  
  let $event := 
    <event xmlns="" name="{$eventId}">
      {let $dataModels := sc:selectDataModels(mba:getConfiguration($mba))
       return
       if ($content) then ( 
         if ($content/@expr) then sync:eval($content/@expr, $dataModels)
         else $content/*
       ) else if($param) then (
         for $p in $param 
           return if($p/@expr)     then sync:eval($p/@expr, $dataModels)
             else if($p/@location) then sync:eval($p/@location, $dataModels)
             else ()
       ) else ()}
    </event>
  
  return mba:enqueueExternalEvent($ancestor, $event)
};

declare updating function sync:assignAncestor($mba        as element(),
                                              $location   as xs:string,
                                              $expression as xs:string?,
                                              $type       as xs:string?,
                                              $attribute  as xs:string?,
                                              $nodelist   as element()*,
                                              $level      as xs:string) {
  let $ancestor := mba:getAncestorAtLevel($mba, $level)
  
  let $configuration := mba:getConfiguration($ancestor)
  let $dataModels := sc:selectDataModels($configuration)
  
  return sc:assign($dataModels, 
                   $location, 
                   $expression, 
                   $type, 
                   $attribute, 
                   $nodelist)
};

(:~
 : 
 :)
declare updating function sync:sendDescendants($mba     as element(),
                                               $eventId as xs:string,
                                               $level   as xs:string,
                                               $stateId as xs:string?,
                                               $cond    as xs:string?,
                                               $param   as element()*,
                                               $content as element()?) {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
    
  let $descendants :=
    if($stateId and not($stateId = '')) then
     $descendants[mba:isInState(., $stateId)]
    else $descendants
    
  let $filtered :=
    if($cond and not($cond = '')) then
      for $descendant in $descendants
        let $dataModels := 
          sc:selectDataModels(mba:getConfiguration($descendant))
        return
          if (sync:eval($cond, $dataModels)) then $descendant
          else ()
    else $descendants
  
  let $event := 
    <event xmlns="" name="{$eventId}">
      {let $dataModels := sc:selectDataModels(mba:getConfiguration($mba))
       return
       if ($content) then ( 
         if ($content/@expr) then sync:eval($content/@expr, $dataModels)
         else $content/*
       ) else if($param) then (
         for $p in $param 
           return if($p/@expr)     then sync:eval($p/@expr, $dataModels)
             else if($p/@location) then sync:eval($p/@location, $dataModels)
             else ()
       ) else ()}
    </event>
  
  for $descendant in $filtered
    return mba:enqueueExternalEvent($descendant, $event)
};

declare updating function sync:assignDescendants($mba        as element(),
                                                 $location   as xs:string,
                                                 $expression as xs:string?,
                                                 $type       as xs:string?,
                                                 $attribute  as xs:string?,
                                                 $nodelist   as element()*,
                                                 $level      as xs:string,
                                                 $stateId    as xs:string?,
                                                 $cond       as xs:string?) {
  let $descendants := mba:getDescendantsAtLevel($mba, $level)
    
  let $descendants :=
    if($stateId and not($stateId = '')) then
     $descendants[mba:isInState(., $stateId)]
    else $descendants
    
  let $filtered :=
    if($cond and not($cond = '')) then
      for $descendant in $descendants
        let $dataModels := 
          sc:selectDataModels(mba:getConfiguration($descendant))
        return
          if (sync:eval($cond, $dataModels)) then $descendant
          else ()
    else $descendants
  
  for $descendant in $filtered
    let $configuration := mba:getConfiguration($descendant)
    let $dataModels := sc:selectDataModels($configuration)
      return sc:assign($dataModels, 
                       $location, 
                       $expression, 
                       $type, 
                       $attribute, 
                       $nodelist)
};

declare updating function sync:newDescendant(
    $mba      as element(),
    $name     as xs:string?,
    $level    as xs:string?,
    $parents  as xs:string?,
    $nodelist as element()*) {
  
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $collection := mba:getCollection($dbName, $collectionName)
  
  let $scxml := mba:getSCXML($mba)
  
  let $configuration := mba:getConfiguration($mba)
  let $dataModels := sc:selectDataModels($configuration)
  
  let $name := 
    if ($name) then sync:eval($name, $dataModels) 
    else functx:capitalize-first($level) || 
      count($collection/mba:mba[@topLevel = $level])
  
  let $parents := 
    if ($parents) then sync:eval($parents, $dataModels) else fn:string($mba/@name)
    
  let $parentElements := 
    for $p in $parents return mba:getMBA($dbName, $collectionName, $p)
  
  let $new := mba:concretize($parentElements, $name, $level)
  
  return (
    insert node $new into 
      $parentElements[1]/mba:concretizations,
    mba:markAsNew($mba)
  )
};

declare function sync:assignNewDescendant($mba        as element(),
                                          $location   as xs:string,
                                          $expression as xs:string?,
                                          $type       as xs:string?,
                                          $attribute  as xs:string?,
                                          $nodelist   as node()*) as element() {
  
  let $scxml := mba:getSCXML($mba)
  let $configuration := mba:getConfiguration($mba)
  let $dataModels := sc:selectDataModels($configuration)
    
  let $variables :=
    for $dataModel at $pos in $dataModels
      for $data in $dataModel/sc:data return 
        'let $' || $data/@id || 
          ' := $dataModels[' || $pos || ']/sc:data[@id = "' || $data/@id || '"] '
  
  let $declareMba :=
    'declare variable $mba external; '
    
  let $declareNodeList :=
    'declare variable $nodelist external; '
        
  let $expression :=
    if (not($expression) or $expression = '') 
    then '() '
    else $expression
  
  return xquery:eval(
    'import module namespace mba  = "http://www.dke.jku.at/MBA";' ||
    'import module namespace sc   = "http://www.w3.org/2005/07/scxml";' ||
    
    $declareMba ||
    $declareNodeList ||
    
    'copy $new := $mba modify ( ' ||
      'let $scxml := mba:getSCXML($new) ' ||
      'let $configuration := mba:getConfiguration($new) ' ||
      'let $dataModels := sc:selectDataModels($configuration) ' ||
      
      fn:string-join($variables) ||
            
      'let $locations := ' || $location || ' ' || (
      
      if ($expression) then
        'let $newValues := ' || $expression || ' '
      else 
        'let $newValues := $nodelist '
      ) || ( 
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
    ) || 
    ') return $new',
    map:merge((map:entry('mba', $mba), map:entry('nodelist', $nodelist)))
  )
};
