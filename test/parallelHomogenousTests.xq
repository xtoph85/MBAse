import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';


declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHomogenous';



(: Create a dedicated collection for heterohomogenous MBA's       
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

(: Concretize HoltonHotelChain on level rental - check if using already existng default-descendants works  
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

(: Try to create a rental MBA by concretizing only one of the 2 required parents - fails because one parent is missing 
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaAustrianPresidentSuite := mba:concretizeParallel($mbaAustria, 'AustrianPresidentSuite', 'rental') 

return $mbaAustrianPresidentSuite  :)

(: Concretize HoltonHotelChain MBA & Austria MBA - produces error because HoltonHotelChain mba is at wrong level 
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:getMBA($db, $collectionName, "Austria")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaAustrianPresidentSuite := mba:concretizeParallel(($mbaHolton, $mbaAustria), 'AustrianPresidentSuite', 'rental') 
return $mbaAustrianPresidentSuite   :)

(: Insert another mba with toplevel country - SCXML of mbaGermany is slighty modified (additional data attribute on level rental)   

let $mbaGermany := <mba xmlns:sc="http://www.w3.org/2005/07/scxml" xmlns:sync="http://www.dke.jku.at/MBA/Synchronization" xmlns="http://www.dke.jku.at/MBA" name="Germany" topLevel="country" hierarchy="parallel" isDefault="true">
  <levels>
    <level name="country">
      <elements>
        <sc:scxml name="Country">
          <sc:datamodel>
            <sc:data id="name"/>
            <sc:data id="vat"/>
            <sc:data id="highSeasonPremium "/>
          </sc:datamodel>
          <sc:initial>
            <sc:transition target="OffSeason"/>
          </sc:initial>
          <sc:state id="OffSeason">
            <sc:transition event="startHighSeason" target="HighSeason"/>
          </sc:state>
          <sc:state id="HighSeason">
            <sc:transition event="endHighSeason" target="OffSeason"/>
          </sc:state>
        </sc:scxml>
      </elements>
    </level>
    <level name="rental">
      <elements>
        <sc:scxml name="Rental">
          <sc:datamodel>
            <sc:data id="renter"/>
            <sc:data id="duration"/>
            <sc:data id="assignedRoom"/>
            <sc:data id="smoker"/>
          </sc:datamodel>
          <sc:initial>
            <sc:transition target="Opening"/>
          </sc:initial>
          <sc:state id="Opening">
            <sc:transition event="setDuration">
              <sc:assign location="$duration" expr="$_event/data/text()"/>
            </sc:transition>
            <sc:transition event="pickupKeys" target="Open"/>
          </sc:state>
          <sc:state id="Open">
            <sc:transition event="returnKeys" target="Settling"/>
          </sc:state>
          <sc:state id="Settling">
            <sc:transition event="close" target="Closed"/>
          </sc:state>
          <sc:state id="Closed"/>
        </sc:scxml>
      </elements>
      <parentLevels>
        <level ref="country"/>
        <level ref="accomodationType"/>
      </parentLevels>
    </level>
  </levels>
  <ancestors>
    <mba xmlns="" ref="HoltonHotelChain"/>
  </ancestors>
</mba>

return mba:insert($db, $collectionName, (), $mbaGermany) :) 

(: Concretize GermanPresidentSuite - should fail because SCXML of germany MBA has been modified  :)
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaGermany := mba:getMBA($db, $collectionName, "Germany")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite") 

let $mbaGermanPresidentSuite := mba:concretizeParallel(($mbaPresidentSuite, $mbaGermany), 'GermanPresidentSuite', 'rental') 
return $mbaGermanPresidentSuite