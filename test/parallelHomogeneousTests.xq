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

declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHomogenous';



(: Create a dedicated collection for homogenous MBA's       
mba:createCollection($db, $collectionName) :)

(: Read Holton Hotel Chain MBA and insert it into db   
let $mbaDocument := fn:doc('D:/workspaces/master/MBAse/example/heteroHomogeneous/HoltonHotelChain-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $mbaDocument/mba:mba
return mba:insert($db, $collectionName, (), $mbaNew) :)


(: Concretize HoltonHotelChain on level rental - check if generating missing default MBAse works - multiple MBA objects are returned  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaHolton, 'AustrianPresidentSuite', 'rental')
return $mbaAustrianPresidentSuite  :)


(: Concretize Holton Hotel Chain MBA - parallel level country  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:concretizeParallel($mbaHolton, 'Austria', 'country')
return mba:insert($db, $collectionName, (), $mbaAustria)    :)


(: Concretize HoltonHotelChain MBA & Austria MBA - proves that a new default-accomodationType-MBA is created to act as ancestor for AustrianPresidentSuite-MBA   
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")

let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaHolton, $mbaAustria), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite :)


(: Concretize Holton Hotel Chain MBA - parallel level accomodationType  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaPresidentSuite := mba:concretizeParallel($mbaHolton, 'PresidentSuite', 'accomodationType')
return mba:insert($db, $collectionName, (), $mbaPresidentSuite) :)


(: Concretize HoltonHotelChain on level rental - check if using already existing default-descendants works  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaHolton, 'AustrianPresidentSuite', 'rental')
return $mbaAustrianPresidentSuite  :)

(: Concretize Austria & PresidentSuite MBA in order to create a rental MBA for a PresidentSuite in Austria 
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaAustria, $mbaPresidentSuite), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite :)

(: Try to create a rental MBA by concretizing only one of the 2 required parents - fails because one parent is missing 
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaAustria, 'AustrianPresidentSuite', 'rental') 

return $mbaAustrianPresidentSuite  :)

(: Concretize HoltonHotelChain MBA & Austria MBA - works because concretize replaces HoltonHotelChain with appropiate default mba :)
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite")         

let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaHolton, $mbaAustria), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite 





