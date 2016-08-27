xquery version "3.0";

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

 : @author Michael Weichselbaumer
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


(: CREATE DB myMBAse D:/Uni/Master/database/XML.zip :)

(: Unit-Test HOW-TO:
    - before-module: import existing example db (from folder or zip file)
    - before-test("someTest"): execute updating operations
    - test: execute read-only operations & unit:assert-equals("..")
    - after-test: restore DB from Backup or reimport (for every test) :)

(: TODO: besprechen wie man das lösen könnte. aufgrund der existierenden einschränkungen geht das so nicht :)
declare %updating %unit:before-module  function mbaTest:createTestDB() {
    let $db := db:list()[matches(.,'^'||$mbaTest:db||'$')]
    return if (fn:empty($db)) then (
        (mba:createMBAse($mbaTest:db),
         mbaTest:createBackup())
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
        unit:assert-equals(functx:node-kind(mba:getMBA($mbaTest:db, $mbaTest:collectionName, 'JohannesKeplerUniversity')), functx:node-kind($mbaWithBoilerPlateElements)))
};