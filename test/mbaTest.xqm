xquery version "3.0";

(:~
: User: mwe
: Date: 09.03.2016
: Time: 10:37
: To change this template use File | Settings | File Templates.
:)



module namespace mbaTest = "http://www.dke.jku.at/MBA/test";

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc='http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';


declare variable $mbaTest:db := 'myMBAse';
declare variable $mbaTest:collectionName := 'parallelHierarchy';


declare %unit:test function mbaTest:void() { () };

declare %unit:test('expected', "err:XPTY0004") function mbaTest:add() {
    123 + 'strings and integers cannot be added'
};

declare %updating %unit:before-module  function mbaTest:createTestDB() {
    let $db := db:list()[matches(.,'^'||$mbaTest:db||'$')]
    return if (fn:empty($db)) then (
        (mba:createMBAse($db), mbaTest:createBackup())
    ) else((
        db:drop($db),
        mba:createMBAse($db),
        mbaTest:createBackup()
    ))
};


declare updating function mbaTest:createBackup() {
    db:create-backup($mbaTest:db)
};

declare %updating %unit:before function mbaTest:restoreBackup() {
    (db:restore($mbaTest:db),
    mba:createCollection($mbaTest:db, $mbaTest:collectionName))
};


declare %unit:test function mbaTest:testEmptyCollection() {
    let $parallelCollection := mba:getCollection($mbaTest:db, $mbaTest:collectionName)/mba:collection
    let $expected := <collection xmlns="http://www.dke.jku.at/MBA" name="parallelHierarchy"/>
    return unit:assert-equals($parallelCollection, $expected)
};


declare %updating %unit:test function mbaTest:testInsertMBA() {
    let $document := fn:doc('D:/workspaces/master/MBAse/example/JKU-MBA-NoBoilerPlateElements.xml')
    let $mbaNew := $document/mba:mba

    let $mbaWithBoilerPlateElements := copy $c := $mbaNew modify (
    mba:addBoilerplateElements($c, $mbaTest:db, $mbaTest:collectionName)
    ) return $c

    return (
        mba:insert($mbaTest:db, $mbaTest:collectionName, (), $mbaNew),
        unit:assert-equals(mba:getMBA($mbaTest:db, $mbaTest:collectionName, 'JohannesKeplerUniversity'), $mbaWithBoilerPlateElements))
};