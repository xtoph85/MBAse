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
import module namespace test='http://www.dke.jku.at/MBA/test' at 'D:/workspaces/master/MBAse/test/mbaTest.xqm';

(: Properties for DB Connection :)

declare variable $db := 'myMBAse';

(:================================================================================================:)

(: Create DB - works only in BaseX client
mba:createMBAse($db) :)


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
let $mbaNew := fn:doc('D:/workspaces/master/MBAse/example/Medical-MBA-NoBoilerPlateElements.xml')
return $mbaNew :)

(:================================================================================================:)


(: Insert mba from external file into database
let $document := fn:doc('D:/workspaces/master/MBAse/example/JKU-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $document/mba:mba
let $collection := 'parallelHierarchy'

(: insert BoilerPlateElements according to parameters
let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $db, $collection)
) return $c  :)

(:
let $databaseName := mba:getDatabaseName($mbaWithBoilerPlateElements)
let $path := db:path($mbaWithBoilerPlateElements)
let $document := db:open($databaseName, 'collections.xml')
let $collectionName := mba:getCollectionName($mbaWithBoilerPlateElements)
let $document := db:open($db, 'collections.xml')
let $collectionEntry := $document/mba:collections/mba:collection[@name = $collectionName]
let $collectionDocument := mba:getCollection($db, $collection)

return $mbaWithBoilerPlateElements :)

(: TODO: find out why mba node seems to be not inside collection node after inserting :)
return mba:insert($db, $collection, (), $mbaNew) :)


(:================================================================================================:)

(: Insert another mba from external file (as descendant) - SoWi
let $document := fn:doc('D:/workspaces/master/MBAse/example/SocialAndEconomicSciences-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $document/mba:mba
let $collection := 'parallelHierarchy'
let $parentMbaName := 'JohannesKeplerUniversity'
let $parent := mba:getMBA($db, $collection, $parentMbaName)

(: insert BoilerPlateElements according to parameters
let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $db, $collection)
) return $c :)


(:
let $collectionVar :=
    db:open($db, 'collections.xml')/mba:collections/mba:collection
    [@name=$collection]
let $collection := mba:getCollection($db, $collection)
let $documentFile := db:open($db, $collectionVar/@file)
let $searchMBA := $documentFile/mba:mba[@name=$parentMbaName]

return $parent :)

return mba:insert($db, $collection, $parent, $mbaNew) :)


(:================================================================================================:)

(: Insert another mba from external file (as descendant) (2nd level descendant)
let $document := fn:doc('D:/workspaces/master/MBAse/example/InformationSystems-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $document/mba:mba
let $collection := 'parallelHierarchy'
let $parentMbaName := 'SocialAndEconomicSciences'
let $parent := mba:getMBA($db, $collection, $parentMbaName)

(: insert BoilerPlateElements according to parameters
let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $db, $collection)
) return $c :)


(:
let $collectionVar :=
    db:open($db, 'collections.xml')/mba:collections/mba:collection
    [@name=$collection]
let $collection := mba:getCollection($db, $collection)
let $documentFile := db:open($db, $collectionVar/@file)
let $searchMBA := $documentFile/mba:mba[@name=$parentMbaName]

return $parent :)

return mba:insert($db, $collection, $parent, $mbaNew)  :)

(:================================================================================================:)

(: Insert another mba from external file (as descendant) - Medical  :)
let $document := fn:doc('D:/workspaces/master/MBAse/example/Medical-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $document/mba:mba
let $collection := 'parallelHierarchy'
let $parentMbaName := 'JohannesKeplerUniversity'
let $parent := mba:getMBA($db, $collection, $parentMbaName)

(: insert BoilerPlateElements according to parameters
let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $db, $collection)
) return $c :)


(:
let $collectionVar :=
    db:open($db, 'collections.xml')/mba:collections/mba:collection
    [@name=$collection]
let $collection := mba:getCollection($db, $collection)
let $documentFile := db:open($db, $collectionVar/@file)
let $searchMBA := $documentFile/mba:mba[@name=$parentMbaName]

return $parent :)

return mba:insert($db, $collection, $parent, $mbaNew)
