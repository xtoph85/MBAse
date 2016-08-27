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

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc='http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';


declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHierarchy';


(:================================================================================================:)

(: Concretize parallel hierarchies :)

(: check if 1 oder 2 parent elemente angegeben:)

(: falls 1 parent element:

     1. check if $topLevel valider level von $parent
     2. wurden alle $parents (Eventuell parallel level) angegeben?
        -> falls nein: füge fehlende parallele levels hinzu (rekursion)
     3. ist $topLevel der zweite level von $parent?
   :)

(: falls 2 parent elemente:

     1. check if $topLevel valider level von $parents
     2. wurden alle $parents (Eventuell parallel level) angegeben?
        -> falls nein: füge fehlende parallel leves hinzu (rekursion)
     3. sind alle $parents teil derselben collection?
     4. haben die ancestors aller parents denselben toplevel?
     5. ist $toplevel der zweite level aller $parents?
  :)

(: in jedem fall:

    1. alle levels des neuen mbas ermitteln
    2. parentLevel-Element des neuen toplevel-Elements entfernen
    3. füge ancestor-referenzen zu den parents hinzu
    4. addBoilerPlateElements
    5. return mba (nicht in db einfügen)



let $collectionName := 'parallelHierarchy'
let $topLevel := 'module'

let $mbaIS := mba:getMBA($db, $collectionName, "InformationSystems")
let $mbaMedical := mba:getMBA($db, $collectionName, "Medical")
let $mbaPhysics := mba:getMBA($db, $collectionName, "Physics")
let $mbaJKU := mba:getMBA($db, $collectionName, "JohannesKeplerUniversity")


let $parents := ($mbaIS, $mbaMedical)

let $validLevel :=
    every $parent in $parents satisfies
        mba:hasLevel($parent, $topLevel)

return mba:getDescendantsAtLevel($mbaJKU, (mba:getSecondLevel($mbaJKU)/@name/data()))[@isDefault = true()]  :)



(:================================================================================================:)

declare function local:concretizeParallelTest($parents as element()*, $name as xs:string, $topLevel as xs:string) {
  let $validLevel :=
    every $parent in $parents satisfies
    mba:hasLevel($parent, $topLevel)
    
  return $validLevel
};



(: Concretize parallel hierarchies pt 2 :)
let $collectionName := 'parallelHierarchy'
let $topLevel := 'module'
let $mbaJKU := mba:getMBA($db, $collectionName, 'JohannesKeplerUniversity')
let $mbaSAES := mba:getMBA($db, $collectionName, 'SocialAndEconomicSciences')
let $mbaIS := mba:getMBA($db, $collectionName, "InformationSystems")


(: Case 1 - concretize second level of one MBA  
return mba:concretizeParallel2($mbaIS, 'CoreCompetenceDKE', 'module') :)



(: Case 2 - concretize third level of one MBA :)
(: This test currently fails because module is a new level introduced by an ancestor of JKU - how am i supposed to handle this? 
return $mbaSAES   :)
(: return local:concretizeParallelTest($mbaJKU, 'CoreCompetenceDKE', 'module')  :)


(: Case 3 - concretize fourth level of one MBA 
return local:concretizeParallelTest($mbaJKU, 'Datenmodellierung', 'course')  :)

(: Case 4 - concretize giving 2 parents if only one is required :)
let $mbaTU := mba:getMBA($db, $collectionName, "TechnicalUniversityVienna")
let $mbaPhysics := mba:getMBA($db, $collectionName, "Physics")
let $parents := ($mbaTU, $mbaPhysics)
let $objectsCreated := ()
let $topLevel := 'program'


return mba:concretize($parents, 'UselessStudies', $topLevel)

(: This block could be useful - or not :)
(: let $parentsAreRelatedToEachOther := 
            some $parent in $parents
            satisfies 
              for $innerParent in $parents
                return if ($parent/@name/data() != $innerParent/@name/data()) then (
                  functx:is-value-in-sequence($parent/@name/data(), mba:getAncestors($innerParent)/@name/data())
                ) else () :)


