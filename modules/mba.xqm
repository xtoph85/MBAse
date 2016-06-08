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
  
 : This module provides basic functionality for the management of
 : databases for multilevel business artifacts (MBAs). 
 
 : @author Christoph Schütz
 :)
module namespace mba='http://www.dke.jku.at/MBA';

import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';

import module namespace sc='http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';

declare updating function mba:createMBAse($newDb as xs:string) {
  let $dbDimSchemaFileName := 'xsd/collections.xsd'
  let $dbDimFileName       := 'collections.xml'
  
  let $dbDimSchema :=
    <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" 
               xmlns:mba="http://www.dke.jku.at/MBA" 
               targetNamespace="http://www.dke.jku.at/MBA"
               elementFormDefault="qualified" 
               attributeFormDefault="unqualified">
      <xs:element name="collections">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="collection" minOccurs="0" maxOccurs="unbounded">
              <xs:complexType>
                <xs:attribute name="name"      type="xs:string"     use="required"/>
                <xs:attribute name="file"      type="xs:string"     use="required"/>
                <xs:attribute name="hierarchy" type="hierarchyType" use="optional" default="complex"/>
              </xs:complexType>
            </xs:element>
          </xs:sequence>
        </xs:complexType>
        <xs:key name="keyCollectionName">
          <xs:selector xpath="mba:collection"/>
          <xs:field xpath="@name"/>
        </xs:key>
        <xs:key name="keyCollectionName">
          <xs:selector xpath="mba:collection"/>
          <xs:field xpath="@file"/>
        </xs:key>
      </xs:element>
      <xs:simpleType name="hierarchyType">
        <xs:restriction base="xs:string">
          <xs:enumeration value="simple"/>
          <xs:enumeration value="parallel"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:schema>
  (: TODO: Fragen ob das anpassen des enum value "parallel" statt "complex" in Ordnung ist :)
  let $dbDimContent := 
    <collections 
      xmlns="http://www.dke.jku.at/MBA" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://www.dke.jku.at/MBA {$dbDimSchemaFileName}"/>
  
  let $mbaSchemaSimple :=
    <xs:schema xmlns="http://www.dke.jku.at/MBA" 
               xmlns:mba="http://www.dke.jku.at/MBA" 
               xmlns:sc="http://www.w3.org/2005/07/scxml"
               xmlns:xs="http://www.w3.org/2001/XMLSchema" 
               targetNamespace="http://www.dke.jku.at/MBA" 
               elementFormDefault="qualified" 
               attributeFormDefault="unqualified">
      <xs:element name="mba">
        <xs:complexType>
          <xs:attribute name="name"      type="xs:string"     use="required"/>
          <xs:attribute name="hierarchy" type="hierarchyType" use="required" default="simple"/>
          <xs:sequence>
            <xs:element name="topLevel" minOccurs="1" maxOccurs="1">
              <xs:complexType>
              </xs:complexType>
            </xs:element>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
      <xs:simpleType name="hierarchyType">
        <xs:restriction base="xs:string">
          <xs:enumeration value="simple"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:schema>
  
  let $mbaSchemaFileNameSimple := 'xsd/mba_simple.xsd'

  (: TODO: mbaSchemaParallel anlegen und in xsd serialisieren :)
  
  return db:create(
    $newDb,
    ($dbDimSchema, $mbaSchemaSimple, $dbDimContent), 
    ($dbDimSchemaFileName, $mbaSchemaFileNameSimple, $dbDimFileName)
  )
};

(:~
 : Insert an MBA with a simple hierarchy (only for simple hierarchies) as a new collection into the database.
 :
 : @param $db the name of the database.
 : @param $mba an MBA with a simple level hierarchy. 
 :)
declare updating function mba:insertAsCollection($db as xs:string,
                                                 $mba as element()) {
  if($mba/@hierarchy = 'simple') then 
    let $document        := db:open($db, 'collections.xml')
    let $collectionName  := $mba/@name
    let $fileName        := 'collections/' || $collectionName || '.xml'
    let $collectionEntry :=
      <collection name='{$collectionName}' file="{$fileName}" hierarchy="simple">
        <uninitialized/>
        <updated/>
      </collection>
    
    return (
      db:add($db, $mba, $fileName),
      insert node $collectionEntry into $document/mba:collections
    )
  else () (: can only insert MBAs with simple hierarchy as collection :)
};

(: Funktion zur Erstellung einer Parallel-Hierarchy-Collection
Zuerst wird createCollection aufgerufen, dann wird mithilfe von insert in die Collection eingefügt :)
declare updating function mba:createCollection($db as xs:string,
        $name as xs:string) {
  let $document        := db:open($db, 'collections.xml')
  let $collectionName  := $name
  let $fileName        := 'collections/' || $collectionName || '.xml'
  let $collectionEntry :=
    <collection name='{$collectionName}' file="{$fileName}" hierarchy="parallel">
      <uninitialized/>
      <updated/>
    </collection>

  let $collectionFile :=
    <collection xmlns="http://www.dke.jku.at/MBA" name="{$collectionName}"/>

  return (
    db:add($db, $collectionFile, $fileName),
    insert node $collectionEntry into $document/mba:collections
  )
};



(: TODO: rausfinden ob es ein concretiez für simple & paralell hierarachies geben soll oder getrennte Funktionen :)
declare function mba:concretize($parents  as element()*,
                                $name     as xs:string,
                                $topLevel as xs:string) as element() {
  let $parent := $parents[1]
  
  let $level := $parent/mba:topLevel//mba:childLevel[@name = $topLevel]
  (: Unterscheidung ob simple oder parallel hierarchy anhand des parent mba
   parents dürfen nicht miteinander in einer konkretisierungsbeziehung stehen (komplizierter als gedacht)
    und müssen in derselben collection sein :)
  
  let $concretization :=
    <mba:mba name="{$name}" hierarchy="simple">
      <mba:topLevel name="{$topLevel}">
        {$level/*}
      </mba:topLevel>
    </mba:mba>

  let $dbName := mba:getDatabaseName($parent)
  let $collectionName := mba:getCollectionName($parent)
  
  let $concretization := copy $c := $concretization modify (
      mba:addBoilerplateElements($c, $dbName, $collectionName)
  ) return $c
  
  return $concretization
};

(:call concretizeParallel2(IsMBa, "CoreCompetenceDKE", "module") :)

declare function mba:concretizeParallel($parents as element()*, $name as xs:string, $topLevel as xs:string) as element()* {
  mba:concretizeParallelAccumulator($parents, $name, $topLevel, ())
};

declare function mba:concretizeParallelAccumulator($parents as element()*, $name as xs:string, $topLevel as xs:string, $objectsCreated as element()*) as element()* {
(: 1. Find out if $level is a valid level in all $parents :)
  let $validLevel :=
    every $parent in $parents satisfies
    mba:hasLevel($parent, $topLevel)

  let $numberOfParents := fn:count($parents)

  return if ($validLevel) then (
  (: 2. Check if $topLevel is second level of $parents :)
  let $parentSecondLevels :=
    distinct-values(
            for $parent in $parents
            return mba:getSecondLevel($parent)/@name/data()
    )
  let $topLevelIsSecondLevelOfAllParents :=
    every $parent in $parents
    satisfies functx:is-value-in-sequence($topLevel, mba:getSecondLevel($parent)/@name/data())


  return if ($topLevelIsSecondLevelOfAllParents) then (

    let $numberOfParentLevelsForTopLevel := fn:count(mba:getLevel($parents[1], $topLevel)/mba:parentLevels/mba:level)

    return if ($numberOfParents = $numberOfParentLevelsForTopLevel) then (
    (: 3. Check if number of parents is correct :)

    (: make concretization :)
    let $parentLevel := functx:remove-elements(
            functx:first-node(
                    mba:getLevel($parents[1], $topLevel)
            ), 'parentLevels')

    let $levelNames := mba:getNonTopLevels($parents[1])/@name/data()
    let $subLevelNames := functx:value-except($levelNames, $parentSecondLevels)

    let $subLevels :=
      for $x in $subLevelNames
      return mba:getLevel($parents[1], $x) (: what about the levels of the possible other parent? merge?:)

    let $ancestorRefs :=
      if ($numberOfParents = 1) then (
        <mba ref="{$parents/@name/data()}"/>
      ) else (
        <mba ref="{$parents[1]/@name/data()}"/>,
        <mba ref="{$parents[2]/@name/data()}"/>
      )

    let $concretization :=
      <mba xmlns="http://www.dke.jku.at/MBA" xmlns:sync="http://www.dke.jku.at/MBA/Synchronization" xmlns:sc="http://www.w3.org/2005/07/scxml" name="{$name}" topLevel="{$topLevel}" hierarchy="parallel" isDefault="true">
        <levels>
          {$parentLevel}
          {$subLevels}
        </levels>
        <ancestors>
          {$ancestorRefs}
        </ancestors>
      </mba>

    return ($concretization, $objectsCreated)
    ) else (
    (: 3. raise error because number of parents is not correct :)
    error(QName('http://www.dke.jku.at/MBA/err',
            'ConcretizeParent'),
            'Missing parent.')
    )

  ) else (
  (: 2. $topLevel is NOT second level of $parents ->
         generate all second level default descendants that are necessary but do not exist :)
  let $secondLevelDefaultDescendantsThatAreGenerated :=
    for $parent in $parents
    let $secondLevels := mba:getSecondLevel($parent)/@name/data()
    for $secondLevel in $secondLevels
    return
      if (fn:empty(mba:getDescendantsAtLevel($parent, $secondLevel)[@isDefault = true()])) then (
      (: 2.1.1 there are no default descendants for second level -> they need to be created :)
      mba:concretizeParallelAccumulator($parent, concat("default", $secondLevel, "Object"), $secondLevel, $objectsCreated)
      ) else ()

  (: load all default descendants that are necessary and already exist (in db) :)
  let $secondLevelDefaultDescendantsThatAlreadyExist :=
    for $parent in $parents
    let $secondLevels := mba:getSecondLevel($parent)/@name/data()
    for $secondLevel in $secondLevels
    return
      if (not(fn:empty(mba:getDescendantsAtLevel($parent, $secondLevel)[@isDefault = true()]))) then (
        mba:getDescendantsAtLevel($parent, $secondLevel)[@isDefault = true()]
      ) else (
      )

  let $secondLevelDefaultDescendants := ($secondLevelDefaultDescendantsThatAlreadyExist, $secondLevelDefaultDescendantsThatAreGenerated)
  return mba:concretizeParallelAccumulator($secondLevelDefaultDescendants, $name, $topLevel, ($objectsCreated, $secondLevelDefaultDescendantsThatAreGenerated))
  )
  ) else (
  (: 1. raise eerror because $topLevel is not a valid level in all $parents :)
  error(QName('http://www.dke.jku.at/MBA/err',
          'ConcretizeParent'),
          'Level is not available in all parents')
  )
};

declare function mba:concretizeParallelDeleteMe($parents as element()*, $name as xs:string, $topLevel as xs:string) as element() {
(: check if 1 oder 2 parent elemente angegeben:)

(: fn:count($parents) :)

  (: 1. Find out if $level is a valid level in all $parents :)
  let $validLevel :=
    every $parent in $parents satisfies
    mba:hasLevel($parent, $topLevel)


  return if ($validLevel) then (
    (: 2. Check if 2 parents have been specified in case of parallel levels :)
    let $noOfParents := fn:count($parents)

    let $parentDirectAncestors :=
      for $parent in $parents
        return mba:getDirectAncestors($parent)

    let $secondLevels :=
      distinct-values(
        for $grandPa in $parentDirectAncestors
          return mba:getSecondLevel($grandPa)/@name/data()
      )

    return if (count($noOfParents) = count($secondLevels)) then (
      (: 3. Check if all parents are in the same collection :)
      let $collectionNames :=
        for $parent in $parents
          return mba:getCollectionName($parent)

      return if (count(distinct-values($collectionNames)) = 1) then (
        (: 4. Check if ancestors of all parents have they same toplevel :)
        let $grandPaTopLevels := $parentDirectAncestors/@toplevel/data()

        return if (every $grandPaTopLevel in $grandPaTopLevels satisfies $grandPaTopLevel = $grandPaTopLevels[1]) then (
          (: 5. Check if $topLevel is the second level of all $parents :)
          if (every $parent in $parents satisfies functx:is-value-in-sequence($topLevel, mba:getSecondLevel($parent)/@name/data())) then (

          ) else (
            (: 5. $topLevel is not the second level of all $parents - generate MBA's for levels in between :)
            (: mba:concretizeParallel(parent, universityGenName, parentSecondLevel),
            mba:concretizeParallel(universityGenMba, name, $topLevel) :)
          )

        ) else (
          (: 4. Ancestors of parents have different toplevel - abort :)
        )
      ) else (
        (: 3. parents are in different collections - abort :)

      )

    ) else (
      (: 2. some parallel level is missing - find out which and call recursion :)
    )

  ) else (()
  (: 1. stop because $topLevel is not a valid level in all $parents :)
  )

};


declare function mba:getLevel($mba as element(), $level as xs:string) as element()* {
  let $level :=
    if($mba/@hierarchy = 'simple') then
      ($mba/mba:topLevel[@name = $level],
      $mba/mba:topLevel//mba:childLevel[@name = $level])
    else (
      $mba/mba:levels//mba:level[@name = $level]
    )
  return $level
};

declare function mba:getSecondLevel($mba as element()) as element()* {
  let $level :=
    if ($mba/@hierarchy = 'simple') then
      (: TODO: test if this works for simply hierarchies :)
      $mba/mba:topLevel/mba:childLevel
    else (
      $mba/mba:levels//mba:level[./mba:parentLevels/mba:level/@ref = $mba/@topLevel/data()]
    )
  return $level
};

declare function mba:getNonTopLevels($mba as element()) as element()* {
  let $level :=
    if ($mba/@hierarchy = 'simple') then
    (: TODO: test if this works for simply hierarchies :)
      $mba/mba:topLevel/mba:childLevel
    else (
      $mba/mba:levels//mba:level[@name != $mba/@topLevel/data()]
    )
  return $level
};

declare function mba:hasLevel($mba as element(), $level as xs:string) as xs:boolean {
  not(fn:empty(mba:getLevel($mba, $level)))
};

declare function mba:getMBA($db             as xs:string,
                            $collectionName as xs:string,
                            $mbaName        as xs:string) {
  let $collection :=
    db:open($db, 'collections.xml')/mba:collections/mba:collection
    [@name=$collectionName]
  
  let $document := db:open($db, $collection/@file)
  let $mba := 
    if($collection/@hierarchy = 'simple') then
      $document/descendant-or-self::mba:mba[@name = $mbaName]
    else (
      $document/descendant-or-self::mba:mba[@name=$mbaName]
    )
  
  return $mba
};

declare function mba:getCollection($db             as xs:string,
                                   $collectionName as xs:string) {
  let $collection :=
    db:open($db, 'collections.xml')/mba:collections/mba:collection
    [@name=$collectionName]
  
  let $document := db:open($db, $collection/@file)
  
  return $document
};

declare function mba:getTopLevelName($mba as element()) as xs:string { 
  if($mba/@hierarchy = 'simple') then
      $mba/mba:topLevel/@name
  else (
      $mba/@topLevel
  )
};

declare function mba:getElementsAtLevel($mba       as element(),
                                        $levelName as xs:string) as element()* { 
  let $level := mba:getLevel($mba, $levelName)

  return $level/mba:elements
};

declare function mba:getSCXML($mba as element()) as element() {
  let $levelName := mba:getTopLevelName($mba)
  let $elements  := mba:getElementsAtLevel($mba, $levelName)
  
  let $scxml :=
    if($elements/@activeVariant) then 
      $elements/sc:scxml[@name = $elements/@activeVariant]
    else $elements/sc:scxml[1]
  
  return $scxml
};

declare updating function mba:addSCXML($mba       as element(),
                                       $levelName as xs:string,
                                       $scxml     as element()) {
  let $elements := mba:getElementsAtLevel($mba, $levelName)
  
  return
    if(not($elements/sc:scxml[@name = $scxml/@name])) then
      insert node $scxml into $elements
    else ()
};

declare updating function mba:removeSCXML($mba       as element(),
                                          $levelName as xs:string,
                                          $scxmlName as xs:string) {
  let $elements := mba:getElementsAtLevel($mba, $levelName)
  
  return
    delete node $elements/sc:scxml[@name = $scxmlName]
};


(: TODO: Support parallel Hierarchies oder remove?? Schütz fragen :)
declare updating function mba:insertLevel($mba             as element(),
                                          $levelName       as xs:string,
                                          $parentLevelName as xs:string,
                                          $childLevelName  as xs:string?) {
  let $parentLevel := $mba/mba:topLevel[@name = $parentLevelName]
  let $parentLevel :=
    if ($parentLevel) then $parentLevel
    else $mba/mba:topLevel//mba:childLevel[@name = $parentLevelName]
  
  let $childLevel := if ($childLevelName) 
    then $mba/mba:topLevel//mba:childLevel[@name = $childLevelName] else ()
  
  let $newLevel :=
    <mba:childLevel name="{$levelName}">
      {$childLevel}
    </mba:childLevel>
  
  return insert node $newLevel into $parentLevel
};

declare function mba:getAncestorsAtLevel($mba   as element(),
                                        $level as xs:string) as element() {
  if($mba/@hierarchy = 'simple') then
    $mba/ancestor::mba:mba[./mba:topLevel/@name = $level]
  else if ($mba/@hierarchy = 'parallel') then 
    let $ancestors := mba:getAncestors($mba)
    return $ancestors[@topLevel = $level]
  else ()
};

declare function mba:getAncestors($mba as element()) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/ancestor::mba:mba
  else (
    let $ancestors := $mba/..//mba:mba[@name = $mba/mba:ancestors/mba:mba/@ref]

    for $ancestor in $ancestors
      return ($ancestor, mba:getAncestors($ancestor))
  )
};

declare function mba:getDirectAncestors($mba as element()) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/ancestor::mba:mba
  else (
    let $ancestors := $mba/..//mba:mba[@name = $mba/mba:ancestors/mba:mba/@ref]
    return $ancestors
  )
};

declare function mba:getDescendants($mba as element()) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/descendant::mba:mba
  else (
    (: let $dbName := mba:getDatabaseName($mba)
    let $collectionNameFromMBA := mba:getCollectionName($mba)
    let $parallelCollection := mba:getCollection($dbName, $collectionNameFromMBA)
    let $descendants := $parallelCollection/mba:mba[./mba:ancestors/mba:mba/@ref=$mba/@name] :)
    let $descendants := $mba/../mba:mba[./mba:ancestors/mba:mba/@ref=$mba/@name]

    for $descendant in $descendants
      return ($descendant, mba:getDescendants($descendant))
  )
};

declare function mba:getDescendantsAtLevel($mba as element(), $level as xs:string) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/descendant::mba:mba[./mba:topLevel/@name = $level]
  else (
    let $descendants := mba:getDescendants($mba)
    return $descendants[@topLevel = $level]
  )
};

declare function mba:isInState($mba as element(), $stateId as xs:string) as xs:boolean {
  let $currentStatus := mba:getCurrentStatus($mba)
  
  return fn:exists($currentStatus/state[@ref=$stateId])
};

declare function mba:getCurrentStatus($mba as element()) as element()* {
  let $scxml := mba:getSCXML($mba)
  let $_x := $scxml/sc:datamodel/sc:data[@id = '_x']
  let $currentStatus := if ($_x) then $_x/currentStatus
    else ()
  
  return $currentStatus
};

declare function mba:getConfiguration($mba as element()) as element()* {
  let $scxml := mba:getSCXML($mba)
  let $currentStatus := mba:getCurrentStatus($mba)
  
  return if ($currentStatus) then
    for $s in $currentStatus/*
      return typeswitch($s)
        case element(initial)
          return $scxml//sc:initial[./parent::sc:scxml/@name = $s/@state or
                                    ./parent::sc:state/@id = $s/@state]
        case element(state)
          return $scxml//sc:state[$s/@ref = ./@id]
        default return ()
   else ()
};

declare updating function mba:addCurrentStates($mba    as element(),
                                               $states as element()*){
  let $currentStatus := mba:getCurrentStatus($mba)
  
  let $newStates := 
    for $state in 
        $states[not (some $s in $currentStatus/* satisfies $s/@ref = ./@id)]
      return <state xmlns="" ref="{$state/@id}"/>
  
  return insert nodes $newStates into $currentStatus
};

declare updating function mba:addCurrentState($mba   as element(),
                                              $state as element()){
  let $currentStatus := mba:getCurrentStatus($mba)
  
  let $newState := 
    <state xmlns="" ref="{$state/@id}"/> 
    
  return insert node $newState into $currentStatus
};

declare updating function mba:removeCurrentStates($mba    as element(),
                                                  $states as element()*){
  let $currentStatus := mba:getCurrentStatus($mba)
  
  let $removeStates := 
    for $s in $states
      return typeswitch($s)
        case element(sc:initial) return 
          typeswitch ($s/..)
            case element(sc:scxml) return 
              $currentStatus/initial[@state=$s/../@name]
            case element(sc:state) return 
              $currentStatus/initial[@state=$s/../@id]
            default return ()
        case element(sc:state) return
          $currentStatus/state[@ref=$s/@id]
        default return ()
    
  return delete nodes $removeStates
};

declare updating function mba:removeCurrentState($mba   as element(),
                                                 $state as element()){
  let $currentStatus := mba:getCurrentStatus($mba)
  
  return delete node $currentStatus/state[@ref=$state/@id]
};

declare function mba:getExternalEventQueue($mba as element()) as element() {
  let $scxml := mba:getSCXML($mba)
  
  return $scxml/sc:datamodel/sc:data[@id = '_x']/externalEventQueue
};

declare updating function mba:enqueueExternalEvent($mba   as element(), 
                                                   $event as element()) {
  let $queue := mba:getExternalEventQueue($mba)
  
  return (
    insert node $event into $queue,
    mba:markAsUpdated($mba)
  )
};


declare function mba:getDatabaseName($mba) {
  let $dbName :=
      if (not (db:name($mba))) then
          mba:getSCXML($mba)/sc:datamodel/sc:data[@id='_x']/db/text()
      else
          db:name($mba)

  return $dbName
};

declare function mba:getCollectionName($mba) {
  let $dbName := mba:getDatabaseName($mba)
  
  let $path :=
    if (not (db:path($mba))) then
      ('collections/' || mba:getSCXML($mba)/sc:datamodel/sc:data[@id='_x']/collection/text() || '.xml')
    else
      db:path($mba)
  
  let $document := db:open($dbName, 'collections.xml')
    
  let $collectionName := 
    $document/mba:collections/mba:collection[@file = $path]/@name
  
  return fn:string($collectionName)
};

(: Neue Funktion die den collectionEntry (Environment) zur Verfüung stellt :)
declare function mba:getCollectionEntry($mba as element())  {
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry :=  $document/mba:collections/mba:collection[@name = $collectionName]

  return $collectionEntry
};


(: Funktion wird vom MultiLevelProcessEnvironment aufgerufen - soll anzeigen dass ein MBA entweder verändert wurde (Attribut)
 oder wenn ein Event enqued wurde :)
declare updating function mba:markAsUpdated($mba as element()) {
  (: let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry := 
    $document/mba:collections/mba:collection[@name = $collectionName] :)
  let $collectionEntry := mba:getCollectionEntry($mba)
  
  return
    insert node <mba ref="{$mba/@name}"/> into $collectionEntry/mba:updated
};

(: Funktion wird vom MultiLevelProcessEnvironment aufgerufen - soll anzeigen dass der Lifecycle eines
  neu erstellten MBAs noch nicht begonnen hat - also quasi nur die Schemadaten vorhanden sind, die Objektdaten aber fehlen:)
declare updating function mba:markAsUninitialized($mba as element()) {
  (: let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)

  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry :=
    $document/mba:collections/mba:collection[@name = $collectionName] :)
  let $collectionEntry := mba:getCollectionEntry($mba)
  
  return
    insert node <mba ref="{$mba/@name}"/> into $collectionEntry/mba:uninitialized
};

(: Gegenstück zur markAsUpdated-Funktion - wird vom MultiLevelProcessEnvironment aufgerufen :)
declare updating function mba:removeFromUpdateLog($mba as element()) {
  (: let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)

  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry :=
    $document/mba:collections/mba:collection[@name = $collectionName] :)
  let $collectionEntry := mba:getCollectionEntry($mba)
  
  return
    delete node functx:first-node(
      $collectionEntry/mba:updated/mba:mba[@ref = $mba/@name]
    )
};
(: Gegenstück zur markAsNew-Funktion - wird vom MultiLevelProcessEnvironment aufgerufen :)
declare updating function mba:removeFromInsertLog($mba as element()) {
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $document := db:open($dbName, 'collections.xml')
  (: TODO: Fragen ob das Absicht ist dass hier @ref referenziert wird während bei den anderen Funtkionen @name verwendet wird :)
  let $collectionEntry := 
    $document/mba:collections/mba:collection[@ref = $collectionName]
  
  return
    delete node functx:first-node(
      $collectionEntry/mba:new/mba:mba[@name = $mba/@name]
    )
};

declare updating function mba:dequeueExternalEvent($mba as element()) {
  let $queue := mba:getExternalEventQueue($mba)
  
  return delete node ($queue/*)[1]
};

declare function mba:getCurrentEvent($mba as element()) as element() {
  let $scxml := mba:getSCXML($mba)
  
  return $scxml/sc:datamodel/sc:data[@id = '_event']
};

declare updating function mba:loadNextExternalEvent($mba as element()) {
  let $queue := mba:getExternalEventQueue($mba)
  let $nextEvent := ($queue/event)[1]
  let $nextEventName := <name xmlns="">{fn:string($nextEvent/@name)}</name>
  let $nextEventData := <data xmlns="">{$nextEvent/*}</data>
  let $currentEvent := mba:getCurrentEvent($mba)
  
  return (
    mba:removeCurrentEvent($mba),
    if ($nextEvent) then insert node $nextEventName into $currentEvent else (),
    if ($nextEvent) then insert node $nextEventData into $currentEvent else (),
    mba:dequeueExternalEvent($mba)
  )
};

declare updating function mba:removeCurrentEvent($mba as element()) {
  let $currentEvent := mba:getCurrentEvent($mba)
  
  return delete nodes $currentEvent/*
};


(: Liefert ein neues MBA zurück ohne es einzufügen, dass soll später mit insert passieren. :)
(: TODO: Support für parallel Hierarchien :)
(: TODO: kann man das auch als nicht update function machen (copy modify etc) :)
declare updating function mba:addBoilerplateElements($mba as element(), $databaseName as xs:string, $collectionName as xs:string) {
  let $scxml := mba:getSCXML($mba)
  
  return (
    if (not ($scxml/sc:datamodel/sc:data[@id = '_event'])) then
      insert node <sc:data id = "_event"/> into $scxml/sc:datamodel
    else (),
    if (not ($scxml/sc:datamodel/sc:data[@id = '_x'])) then
      insert node 
        <sc:data id = "_x">
          <db xmlns="">{$databaseName}</db>
          <collection xmlns="">{$collectionName}</collection>
          <name xmlns="">{fn:string($mba/@name)}</name>
          <currentStatus xmlns=""/>
          <externalEventQueue xmlns=""/>
        </sc:data>
      into $scxml/sc:datamodel
    else (),
    if ($mba/@hierarchy = 'parallel') then (
        if (not ($mba/mba:abstractions)) then
          insert node <mba:abstractions/> into $mba
        else (),
        if (not ($mba/mba:conretizations)) then
          insert node <mba:concretizations/> into $mba
        else (),
        if (not ($mba/mba:ancestors)) then
          insert node <mba:ancestors/> into $mba
        else (),
        if (not ($mba/mba:descendants)) then
          insert node <mba:descendants/> into $mba
        else ()
    ) else()
  )
};



(: Die insert-Funktion verarbeitet nur konsistente MBAs von parallelen Hierarchien (die also auch schon Boilerplate-Elements enthalten :)
declare updating function mba:insert($db as xs:string, $collection as xs:string, $parents as element()*, $mba as element()) {
  let $collectionDocument := mba:getCollection($db, $collection)
  let $mbaWithBoilerPlateElements := copy $c := $mba modify (
      mba:addBoilerplateElements($c, $db, $collection)
  ) return $c

  return (
    insert node $mbaWithBoilerPlateElements into $collectionDocument,

    if (not(fn:empty($parents))) then
      insert node <mba ref="{$mba/@name}"/> into $parents/mba:concretizations
    else(),

    mba:markAsUninitialized($mbaWithBoilerPlateElements)
  )

};

(: TODO: diese Funktion wirklich notwendig? kann man doch mithilfe von insert auch erledigen?! :)
declare updating function mba:insertDescendant($mba as element(), $descendant as element()) {
  ()
};



(: TODO: insert and getDescendants und :)