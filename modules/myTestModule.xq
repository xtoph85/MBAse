xquery version "3.0";

(:~
: User: mwe
: Date: 26.12.2015
: Time: 12:42
: To change this template use File | Settings | File Templates.
:)

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc='http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';

(: Properties for DB Connection :)

declare variable $db := 'myMBAse';

(:================================================================================================:)

(: Open DB and return complete content - for verifying everything works
let $var := db:open($db)
return $var :)

(:================================================================================================:)

(: Select a mba from db and return it
declare variable $collection := 'JohannesKeplerUniversity';
declare variable $mbaName := 'SocialAndEconomicSciences';

let $mba := mba:getMBA($db, $collection, $mbaName)
return $mba :)

(:================================================================================================:)


(: Select scxml section of mba from database
declare variable $collection := 'JohannesKeplerUniversity';
declare variable $mbaName := 'SocialAndEconomicSciences';

let $mba := mba:getMBA($db, $collection, $mbaName)
let $scxml := mba:getSCXML($mba)
return $scxml :)

(:================================================================================================:)

(: Create a new collection - note that Exception is logged because there is no return value
let $collectionName := 'parallelHierarchy'
return mba:createCollection($db, $collectionName) :)

(:================================================================================================:)


(: Return newly created collection
let $parallelCollection := mba:getCollection($db, 'parallelHierarchy')
return $parallelCollection :)

(:================================================================================================:)


(: Read mba from external file
let $mbaNew := fn:doc('D:/workspaces/master/MBAse/example/JKU-MBA-NoBoilerPlateElements.xml')
return $mbaNew :)

(:================================================================================================:)


(: Insert mba from external file into database  :)
let $document := fn:doc('D:/workspaces/master/MBAse/example/JKU-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $document/mba:mba
let $collection := 'parallelHierarchy'

let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $db, $collection)
) return $c

(:
let $databaseName := mba:getDatabaseName($mbaWithBoilerPlateElements)
let $path := db:path($mbaWithBoilerPlateElements)

let $document := db:open($databaseName, 'collections.xml')


let $collectionName := mba:getCollectionName($mbaWithBoilerPlateElements)

let $document := db:open($db, 'collections.xml')
let $collectionEntry := $document/mba:collections/mba:collection[@name = $collectionName]
let $collectionDocument := mba:getCollection($db, $collection)

return $collectionDocument :)

return mba:insert($db, $collection, (), $mbaNew)