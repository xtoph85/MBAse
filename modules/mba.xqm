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

import module namespace functx = 'http://www.functx.com' at 'functx.xqm';

import module namespace sc='http://www.w3.org/2005/07/scxml' at 'scxml.xqm';

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
          <xs:enumeration value="complex"/>
        </xs:restriction>
      </xs:simpleType>
    </xs:schema>
    
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




declare function mba:concretize($parents  as element()*,
                                $name     as xs:string,
                                $topLevel as xs:string) as element() {
  let $parent := $parents[1]
  
  let $level := $parent/mba:topLevel//mba:childLevel[@name = $topLevel]
  
  let $concretization :=
    <mba:mba name="{$name}" hierarchy="simple">
      <mba:topLevel name="{$topLevel}">
        {$level/*}
      </mba:topLevel>
    </mba:mba>
  
  let $concretization := copy $c := $concretization modify (
      mba:addBoilerplateElements($c)
  ) return $c
  
  return $concretization
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
    else ()
  
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
  if($mba/@hierarchy = 'simple') then $mba/mba:topLevel/@name else ()
};

declare function mba:getElementsAtLevel($mba       as element(),
                                        $levelName as xs:string) as element()* { 
  let $level :=
    if($mba/@hierarchy = 'simple') then 
      ($mba/mba:topLevel[@name = $levelName],
       $mba/mba:topLevel//mba:childLevel[@name = $levelName])
    else ()
  
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

declare function mba:getAncestorAtLevel($mba   as element(),
                                        $level as xs:string) as element() {
  if($mba/@hierarchy = 'simple') then
    $mba/ancestor::mba:mba[./mba:topLevel/@name = $level]
  else ()
};

declare function mba:getAncestors($mba   as element()) as element() {
  if($mba/@hierarchy = 'simple') then
    $mba/ancestor::mba:mba
  else ()
};

declare function mba:getDescendants($mba as element()) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/descendant::mba:mba
  else ()
};

declare function mba:getDescendantsAtLevel($mba   as element(),
                                           $level as xs:string) as element()* {
  if($mba/@hierarchy = 'simple') then
    $mba/descendant::mba:mba[./mba:topLevel/@name = $level]
  else ()
};

declare function mba:isInState($mba     as element(),
                               $stateId as xs:string) as xs:boolean {
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
  let $dbName := db:name($mba)
  
  return $dbName
};

declare function mba:getCollectionName($mba) {
  let $dbName := mba:getDatabaseName($mba)
  let $path := db:path($mba)
  
  let $document := db:open($dbName, 'collections.xml')
    
  let $collectionName := 
    $document/mba:collections/mba:collection[@file = $path]/@name
  
  return fn:string($collectionName)
};


(: Funktion wird vom MultiLevelProcessEnvironment aufgerufen - soll anzeigen dass ein MBA entweder verändert wurde (Attribut)
 oder wenn ein Event enqued wurde :)
declare updating function mba:markAsUpdated($mba as element()) {
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry := 
    $document/mba:collections/mba:collection[@name = $collectionName]
  
  return
    insert node <mba ref="{$mba/@name}"/> into $collectionEntry/mba:updated
};

(: Funktion wird vom MultiLevelProcessEnvironment aufgerufen - soll anzeigen dass der Lifecycle eines
  neu erstellten MBAs noch nicht begonnen hat - also quasi nur die Schemadaten vorhanden sind, die Objektdaten aber fehlen:)
declare updating function mba:markAsUninitialized($mba as element()) {
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry := 
    $document/mba:collections/mba:collection[@name = $collectionName]
  
  return
    insert node <mba ref="{$mba/@name}"/> into $collectionEntry/mba:new
};

(: Gegenstück zur markAsUpdated-Funktion - wird vom MultiLevelProcessEnvironment aufgerufen :)
declare updating function mba:removeFromUpdateLog($mba as element()) {
  let $dbName := mba:getDatabaseName($mba)
  let $collectionName := mba:getCollectionName($mba)
  
  let $document := db:open($dbName, 'collections.xml')
  let $collectionEntry := 
    $document/mba:collections/mba:collection[@name = $collectionName]
  
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

declare updating function mba:addBoilerplateElements($mba as element()) {
  let $scxml := mba:getSCXML($mba)
  
  return (
    if (not ($scxml/sc:datamodel/sc:data[@id = '_event'])) then
      insert node <sc:data id = "_event"/> into $scxml/sc:datamodel
    else (),
    if (not ($scxml/sc:datamodel/sc:data[@id = '_x'])) then
      insert node 
        <sc:data id = "_x">
          <db xmlns="">{mba:getDatabaseName($mba)}</db>
          <collection xmlns="">{mba:getCollectionName($mba)}</collection>
          <name xmlns="">{fn:string($mba/@name)}</name>
          <currentStatus xmlns=""/>
          <externalEventQueue xmlns=""/>
        </sc:data>
      into $scxml/sc:datamodel
    else (),
    if (not ($mba/mba:concretizations)) then
      insert node <mba:concretizations/> into $mba
    else (),
    if ($mba/@hierarchy = 'parallel') then
      if (not ($mba/mba:abstractions)) then
        insert node <mba:abstractions/> into $mba
      else if (not ($mba/mba:ancestors)) then
        insert node <mba:ancestors/> into $mba
      else if (not ($mba/mba:descendants)) then
          insert node <mba:descendants/> into $mba
      else()
    else()
    (:)if ($mba/@hierarchy = 'parallel') then
      if (not ($mba/mba:ancestors)) then
        insert node <mba:ancestors/> into $mba
      else ()
    else (),
    if ($mba/@hierarchy = 'parallel') then
      if (not ($mba/mba:descendants)) then
        insert node <mba:descendants/> into $mba
      else ()
    else ()
  )
};



(: Bei beiden insert-Funktionen dürfen nur konsistente MBAs eingefügt werden (die also auch schon Boilerplate-Elements enthalten :)
(: Diese Funktion kann eigentlich nur für MBAs mit Parallel Hierarchies Sinn, weil nur diese MBAs einen Verweis auf die Parent-MBAs haben.
Das muss hier also überprüft werden (Beispiel gibt's in den anderen Funktionen) :)
(: Beide Funktionen benoetigen ein if zur Unterscheid ob simple oder parallel hierarchy. :)
declare updating function mba:insert($db as xs:string,
        $collection as xs:string,
        $mba as element()) {
  ()
};

(: Diese Funktion ist allgemein für Parallel und Simple Hierarchies verwendbar.
Wenn das übergebene MBA keinen abstractions-Tag hat, dann soll dieser eingefügt werden je nach Information,
die in $parents enthalten ist. $parents soll die MBA nodes enthalten, also die identity soll hier preserved werden.
Wir programmieren fast objekt-orientiert, node identity bleibt durch eine selection eines Nodes grundsätzlich erhalten. :)
(: Liefert ein neues MBA zurück ohne es einzufügen, dass soll später mit insert passieren.
Funktioniert bisher nur mit Simple Hiearchies, muss also für Parallel Hierarchies erweitert werden :)
declare updating function mba:insert($db as xs:string,
        $collection as xs:string,
        $parents as element()*,
        $mba as element()) {
  ()
};
