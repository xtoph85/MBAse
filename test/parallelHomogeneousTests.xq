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
return $mbaAustrianPresidentSuite   :)

(: Concretize Holton Hotel Chain MBA - parallel level accomodationType  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaPresidentSuite := mba:concretizeParallel($mbaHolton, 'PresidentSuite', 'accomodationType')
return mba:insert($db, $collectionName, (), $mbaPresidentSuite) :)


(: Concretize Holton Hotel Chain MBA - parallel level country 
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:concretizeParallel($mbaHolton, 'Austria', 'country')
return mba:insert($db, $collectionName, (), $mbaAustria)   :) 

(: Concretize HoltonHotelChain on level rental - check if using already existing default-descendants works  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaHolton, 'AustrianPresidentSuite', 'rental')
return $mbaAustrianPresidentSuite  :)

(: Concretize Austria & PresidentSuite MBA in order to create a rental MBA for a PresidentSuite in Austria
[If concretize is called with only parent MBA this still works because I don't know how to detect the error 
Using grandparent MBA does not work because new levels can be introduced by MBA's so its no use to check grandparents] -> solved this problem  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaAustria, $mbaPresidentSuite), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite :)

(: Try to create a rental MBA by concretizing only one of the 2 required parents - fails because one parent is missing :)
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaAustria, 'AustrianPresidentSuite', 'rental') 

return $mbaAustrianPresidentSuite  

(: Concretize HoltonHotelChain MBA & Austria MBA - produces error because HoltonHotelChain mba is at wrong level  
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 
let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaHolton, $mbaAustria), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite  :)




