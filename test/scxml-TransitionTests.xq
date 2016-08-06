import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';
import module namespace scx='http://www.w3.org/2005/07/scxml/extension/' at 'D:/workspaces/master/MBAse/modules/scxml_extension.xqm';
import module namespace scc='http://www.w3.org/2005/07/scxml/consistency/' at 'D:/workspaces/master/MBAse/modules/scxml_consistency.xqm';

let $scxmlRentalOriginal :=<sc:scxml name="RenterType">
					<sc:datamodel>
					  <sc:data id="_event"/>
					  <sc:data id="_x">
					  </sc:data>
					</sc:datamodel>
					<sc:initial>
					  <sc:transition target="InDevelopment"/>
					</sc:initial>
					<sc:state id="InDevelopment">
					  <sc:transition event="setMaximumRate"/>
					  <sc:transition event="launch" target="OnOffer"/>
					</sc:state>
					<sc:state id="OnOffer">
						<sc:transition event="openRental"/>
						<sc:transition event="cancel" target="Cancelled"/>
					</sc:state>
					<sc:state id="Cancelled">
						<sc:transition event="discontinue" target="Discontinued"/>
					</sc:state>
					<sc:state id="Discontinued" mba:isArchiveState="true"/>
				</sc:scxml>


(: Check if SCXML Transition Behavior works as expected. Refined SCXML with additional substates and refined transitions. expected result: true 
let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)


(: Check if transition consistency check is able to detect a missing transition in refined model. expected result: error 
Missing transition "discontinue" in state "Canceled" 

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Modle</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if SCXML Transition Behavior works as expected. Refined model with parallel region (new states). expected result: true 
State "Cancel" is now embedded in a parallel region with a new state "AdditionalState" 

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
            <sc:parallel id="ParallelRegion">
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
              <sc:state id="AdditionalState">
              </sc:state>
             </sc:parallel>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if refined transition with invalid target state is detected. expected result: false
State "PhasingOut" has transition "cancel" with target "Discontinued" instead of "Cancelled"  

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Discontinued"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>

return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)


(: Introduce event descriptor on transition. expected result: true 
Original model gets new eventless transition in state "OnOffer" - Refined Model adds event to transition 

let $scxmlRentalOriginal :=<sc:scxml name="RenterType">
					<sc:datamodel>
					  <sc:data id="_event"/>
					  <sc:data id="_x">
					  </sc:data>
					</sc:datamodel>
					<sc:initial>
					  <sc:transition target="InDevelopment"/>
					</sc:initial>
					<sc:state id="InDevelopment">
					  <sc:transition event="setMaximumRate"/>
					  <sc:transition event="launch" target="OnOffer"/>
					</sc:state>
					<sc:state id="OnOffer">
						<sc:transition event="openRental"/>
						<sc:transition event="cancel" target="Cancelled"/>
            <sc:transition target ="Discontinued" />
					</sc:state>
					<sc:state id="Cancelled">
						<sc:transition event="discontinue" target="Discontinued"/>
					</sc:state>
					<sc:state id="Discontinued" mba:isArchiveState="true"/>
				</sc:scxml>
        
        
let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
                 <sc:transition event="killImmediately" target="Discontinued" />
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if a refined event descriptor is accepted. expected result: true 
Event descriptor original "launch" -> refined: "launch.active"  

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch.active" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if an additional event descriptor is accepted. expected result: false
Event descriptor original "launch" -> refined: "launch event2" 

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch event2" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if a new transition in refined model between existing states is detected. expected result: error 
State "Canceled" gets new transition with target state "Discontinued" 
let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
                <sc:transition event="anotherEvent" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>


return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined)  :)

(: Check if replaced event descriptor in refined model is detected. expected result: false
State "InDevelopment" - transition with targetstate "Active" has another event descriptor in refined model
let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="otherEvent" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined) :)

(: Check if transition with wrong source state is detected. expected result: false
Transition "setMaximumRate" is no longer nested in state "InDevelopment" but in state "Active" (substate of "OnOffer")

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
                <sc:transition event="setMaximumRate"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>
    
return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginal, $scxmlRentalRefined)  :)

(: Check if transition with modified condition (additional AND-Clause) is accepted. expected result: true
A condition is added to transition "setMaximumRate" in original scxml and is extended by and clause in refined scxml :)
let $scxmlRentalOriginalWithCondition :=<sc:scxml name="RenterType">
					<sc:datamodel>
					  <sc:data id="_event"/>
					  <sc:data id="_x">
					  </sc:data>
            <sc:data id="creditScore"/>
					</sc:datamodel>
					<sc:initial>
					  <sc:transition target="InDevelopment"/>
					</sc:initial>
					<sc:state id="InDevelopment">
					  <sc:transition event="setMaximumRate" cond="$creditScore &gt; 0"/>
					  <sc:transition event="launch" target="OnOffer"/>
					</sc:state>
					<sc:state id="OnOffer">
						<sc:transition event="openRental"/>
						<sc:transition event="cancel" target="Cancelled"/>
					</sc:state>
					<sc:state id="Cancelled">
						<sc:transition event="discontinue" target="Discontinued"/>
					</sc:state>
					<sc:state id="Discontinued" mba:isArchiveState="true"/>
				</sc:scxml>
        

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
              <sc:data id="afternoon"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate" cond="$afternoon and $creditScore &gt; 0"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>

let $origCond := "$creditScore &gt; 0"
let $newCond := "$afternoon and $creditScore &gt; 0"

(: return fn:compare($origCond, fn:substring($newCond, fn:string-length($newCond) - fn:string-length($origCond)+ 1, fn:string-length($newCond)))  

return fn:compare(' and', fn:substring($newCond, fn:string-length($newCond) - fn:string-length($origCond) - 4, 4)) :)


return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginalWithCondition, $scxmlRentalRefined)  

(: Check if transition that is missing in refined model is detected. expected result: false
A condition is added to transition "setMaximumRate" in original scxml and is not available in refined scxml
let $scxmlRentalOriginalWithCondition :=<sc:scxml name="RenterType">
					<sc:datamodel>
					  <sc:data id="_event"/>
					  <sc:data id="_x">
					  </sc:data>
            <sc:data id="creditScore"/>
					</sc:datamodel>
					<sc:initial>
					  <sc:transition target="InDevelopment"/>
					</sc:initial>
					<sc:state id="InDevelopment">
					  <sc:transition event="setMaximumRate" cond="$creditScore &gt; 0"/>
					  <sc:transition event="launch" target="OnOffer"/>
					</sc:state>
					<sc:state id="OnOffer">
						<sc:transition event="openRental"/>
						<sc:transition event="cancel" target="Cancelled"/>
					</sc:state>
					<sc:state id="Cancelled">
						<sc:transition event="discontinue" target="Discontinued"/>
					</sc:state>
					<sc:state id="Discontinued" mba:isArchiveState="true"/>
				</sc:scxml>
        

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>

return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginalWithCondition, $scxmlRentalRefined) :)

(: Check if transition with modified condition (replace original condition) is accepted. expected result: false
A condition is added to transition "setMaximumRate" in original scxml and is replace by onther condition in refined scxml 
let $scxmlRentalOriginalWithCondition :=<sc:scxml name="RenterType">
					<sc:datamodel>
					  <sc:data id="_event"/>
					  <sc:data id="_x">
					  </sc:data>
            <sc:data id="creditScore"/>
					</sc:datamodel>
					<sc:initial>
					  <sc:transition target="InDevelopment"/>
					</sc:initial>
					<sc:state id="InDevelopment">
					  <sc:transition event="setMaximumRate" cond="$creditScore &gt; 0"/>
					  <sc:transition event="launch" target="OnOffer"/>
					</sc:state>
					<sc:state id="OnOffer">
						<sc:transition event="openRental"/>
						<sc:transition event="cancel" target="Cancelled"/>
					</sc:state>
					<sc:state id="Cancelled">
						<sc:transition event="discontinue" target="Discontinued"/>
					</sc:state>
					<sc:state id="Discontinued" mba:isArchiveState="true"/>
				</sc:scxml>
        

let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Refined Model</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x"/>
              <sc:data id="$afternoon"/>
						</sc:datamodel>
						<sc:initial>
							<sc:transition target="InDevelopment"/>
						</sc:initial>
						<sc:state id="InDevelopment">
							<sc:transition event="setMaximumRate" cond="$afternoon"/>
							<sc:transition event="launch" target="Active"/>
						</sc:state>
						<sc:state id="OnOffer">
							<sc:state id="Active">
								<sc:transition event="openRental"/>
								<sc:transition event="phaseOut" target="PhasingOut"/>
							</sc:state>
							<sc:state id="PhasingOut">
								<sc:transition event="cancel" target="Cancelled"/>
							</sc:state>
						</sc:state>
						  <sc:state id="Cancelled">
							  <sc:transition event="discontinue" target="Discontinued"/>
						  </sc:state>
						<sc:state id="Discontinued" mba:isArchiveState="true"/>
					</sc:scxml>

return scc:isEveryOriginalTransitionInRefined($scxmlRentalOriginalWithCondition, $scxmlRentalRefined) :)
