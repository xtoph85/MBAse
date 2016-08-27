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
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';
import module namespace scx='http://www.w3.org/2005/07/scxml/extension/' at 'D:/workspaces/master/MBAse/modules/scxml_extension.xqm';
import module namespace scc='http://www.w3.org/2005/07/scxml/consistency/' at 'D:/workspaces/master/MBAse/modules/scxml_consistency.xqm';
import module namespace reflection='http://www.dke.jku.at/MBA/Reflection' at 'D:/workspaces/master/MBAse/modules/reflection.xqm';

declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHomogenous';

declare variable $mbaHoltonFromDB := mba:getMBA($db, $collectionName, "HoltonHotelChain");
declare variable $mbaAustriaFromDB := mba:getMBA($db, $collectionName, "Austria");

declare variable $mbaDocument := fn:doc('D:/workspaces/master/MBAse/example/heteroHomogeneous/HoltonHotelChain-MBA-NoBoilerPlateElements.xml');
declare variable $mbaHolton := $mbaDocument/mba:mba;

(: Check if refined model is behavior consistent to original model. expected result: true)
   This test is here because it is a precondition for the following tests regarding reflective functions 
return scc:isBehaviorConsistentSpecialization($scxmlRentalOriginal, $scxmlRentalRefined) :)

declare variable $subState := 
  <sc:state id="RunningGood">   
  </sc:state>;

declare variable $originalState :=  $mbaHolton//sc:state[@id='Running'];



(: Check if non-updating version of refine state function works.
Using an MBA that is loaded from file system makes it easier to be sure it has no descendants. expected result: refined state node  :)
let $subState := 
  <sc:state id="RunningGood">   
  </sc:state>

return reflection:getRefinedState($originalState, $subState)    

(: Chif if a final node can also be inserted using the refine state function. expected result: refined state node 
let $finalState := 
  <sc:final id="TheEnd">   
  </sc:final>
  
return reflection:getRefinedState($originalState, $finalState)  :)


(: Check if updating version of refine state function works. Backup is necessary before executing this test.   
declare variable $originalStateAustriaFromDB := $mbaAustriaFromDB//sc:state[@id='OffSeason'];
declare variable $subStateAustriaFromDB := 
  <sc:state id="StaffHome">
  </sc:state>;  :)
  

(: Step 1: execute updating function
   Step 2: return variable :)  
(:reflection:refineState($originalStateAustriaFromDB, $subStateAustriaFromDB):)
(: $mbaAustriaFromDB :)

  
(: Check if refineState fails if an MBA has already descendants: expected: error 
For this purpose MBA is loaded from database  
declare variable $originalStateFromDB :=  $mbaHoltonFromDB//sc:state[@id='Running'];
reflection:refineState($originalStateFromDB, $subState) :)

