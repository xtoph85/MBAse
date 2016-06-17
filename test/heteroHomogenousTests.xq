import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';


declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHeteroHomogenous';


(: Create a dedicated collection for heterohomogenous MBA's     
mba:createCollection($db, $collectionName) :)  

(: Read Holton Hotel Chain MBA and insert it into db 
let $mbaDocument := fn:doc('D:/workspaces/master/MBAse/example/heteroHomogeneous/HoltonHotelChain-MBA-NoBoilerPlateElements.xml')
let $mbaNew := $mbaDocument/mba:mba
return mba:insert($db, $collectionName, (), $mbaNew) :)


(: Concretize Holton Hotel Chain MBA - parallel level accomodationType 
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaPresidentSuite := mba:concretizeParallel($mbaHolton, 'PresidentSuite', 'accomodationType')
return mba:insert($db, $collectionName, (), $mbaPresidentSuite) :)


(: Concretize Holton Hotel Chain MBA - parallel level country 
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaAustria := mba:concretizeParallel($mbaHolton, 'Austria', 'country')
return mba:insert($db, $collectionName, (), $mbaAustria)   :)




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


(: Concretize GermanPresidentSuite - should fail because SCXML of germany MBA has been modified :)
let $mbaHolton := mba:getMBA($db, $collectionName, "HoltonHotelChain")
let $mbaGermany := mba:getMBA($db, $collectionName, "Germany")
let $mbaPresidentSuite := mba:getMBA($db, $collectionName, "PresidentSuite")

let $mbaGermanPresidentSuite := mba:concretize(($mbaPresidentSuite, $mbaGermany), 'GermanPresidentSuite', 'rental')
return $mbaGermanPresidentSuite  