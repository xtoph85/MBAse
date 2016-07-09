import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';
import module namespace scx='http://www.w3.org/2005/07/scxml/extension/' at 'D:/workspaces/master/MBAse/modules/scxml_extension.xqm';

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


let $scxmlRentalRefined := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Test MBA for cancel early cancel late</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x">
								<db xmlns="">myMBAse</db>
								<collection xmlns="">CancelEarlyLate</collection>
								<mba xmlns="">Private1</mba>
								<currentStatus xmlns="">
									<state ref="Discontinued"/>
								</currentStatus>
								<externalEventQueue xmlns=""/>
								<xes:log xmlns:xes="http://www.xes-standard.org/">
									<xes:trace>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T06:00:00.000+02:00"/>
											<xes:string key="sc:initial" value="RenterType"/>
											<xes:string key="sc:target" value="InDevelopment"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:00:00.500+02:00"/>
											<xes:string key="sc:state" value="InDevelopment"/>
											<xes:string key="concept:name" value="launch"/>
											<xes:string key="sc:event" value="launch"/>
											<xes:string key="sc:target" value="Active"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:30:00.500+02:00"/>
											<xes:string key="sc:state" value="Active"/>
											<xes:string key="concept:name" value="phaseOut"/>
											<xes:string key="sc:event" value="phaseOut"/>
											<xes:string key="sc:target" value="PhasingOut"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T08:30:00.500+02:00"/>
											<xes:string key="sc:state" value="PhasingOut"/>
											<xes:string key="concept:name" value="cancel"/>
											<xes:string key="sc:event" value="cancel"/>
											<xes:string key="sc:target" value="Cancelled"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T09:00:00.500+02:00"/>
											<xes:string key="sc:state" value="Cancelled"/>
											<xes:string key="concept:name" value="discontinue"/>
											<xes:string key="sc:event" value="discontinue"/>
											<xes:string key="sc:target" value="Discontinued"/>
										</xes:event>
									</xes:trace>
								</xes:log>
							</sc:data>
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
         
          
let $statesOriginal := sc:getAllStates($scxmlRentalOriginal)
let $statesRefined := sc:getAllStates($scxmlRentalRefined)

(: Check if all states from U are available in U' and have the correct ancestor (substates!)      
return sc:isEveryOriginalStateInRefined($statesOriginal, $statesRefined) :)  

(: Check if all states from U are available in U' -> state "Discontinued" from U is missing U' -> expected false        
let $scxmlRentalRefinedMissingState := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Test MBA for cancel early cancel late</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x">
								<db xmlns="">myMBAse</db>
								<collection xmlns="">CancelEarlyLate</collection>
								<mba xmlns="">Private1</mba>
								<currentStatus xmlns="">
									<state ref="Discontinued"/>
								</currentStatus>
								<externalEventQueue xmlns=""/>
								<xes:log xmlns:xes="http://www.xes-standard.org/">
									<xes:trace>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T06:00:00.000+02:00"/>
											<xes:string key="sc:initial" value="RenterType"/>
											<xes:string key="sc:target" value="InDevelopment"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:00:00.500+02:00"/>
											<xes:string key="sc:state" value="InDevelopment"/>
											<xes:string key="concept:name" value="launch"/>
											<xes:string key="sc:event" value="launch"/>
											<xes:string key="sc:target" value="Active"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:30:00.500+02:00"/>
											<xes:string key="sc:state" value="Active"/>
											<xes:string key="concept:name" value="phaseOut"/>
											<xes:string key="sc:event" value="phaseOut"/>
											<xes:string key="sc:target" value="PhasingOut"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T08:30:00.500+02:00"/>
											<xes:string key="sc:state" value="PhasingOut"/>
											<xes:string key="concept:name" value="cancel"/>
											<xes:string key="sc:event" value="cancel"/>
											<xes:string key="sc:target" value="Cancelled"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T09:00:00.500+02:00"/>
											<xes:string key="sc:state" value="Cancelled"/>
											<xes:string key="concept:name" value="discontinue"/>
											<xes:string key="sc:event" value="discontinue"/>
											<xes:string key="sc:target" value="Discontinued"/>
										</xes:event>
									</xes:trace>
								</xes:log>
							</sc:data>
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
					</sc:scxml>
          
          
return sc:isEveryOriginalStateInRefined($statesOriginal, $scxmlRentalRefinedMissingState) :)

(:Check if all states from U are in U' -> state "Discontinued" from U is "moved" in U' and has wrong ancestor -> expected: false :)
let $scxmlRentalRefinedStateHasWrongAncestor := <sc:scxml name="RenterType">
						<sc:datamodel>
							<sc:data id="description">Test MBA for cancel early cancel late</sc:data>
							<sc:data id="_event"/>
							<sc:data id="_x">
								<db xmlns="">myMBAse</db>
								<collection xmlns="">CancelEarlyLate</collection>
								<mba xmlns="">Private1</mba>
								<currentStatus xmlns="">
									<state ref="Discontinued"/>
								</currentStatus>
								<externalEventQueue xmlns=""/>
								<xes:log xmlns:xes="http://www.xes-standard.org/">
									<xes:trace>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T06:00:00.000+02:00"/>
											<xes:string key="sc:initial" value="RenterType"/>
											<xes:string key="sc:target" value="InDevelopment"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:00:00.500+02:00"/>
											<xes:string key="sc:state" value="InDevelopment"/>
											<xes:string key="concept:name" value="launch"/>
											<xes:string key="sc:event" value="launch"/>
											<xes:string key="sc:target" value="Active"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T07:30:00.500+02:00"/>
											<xes:string key="sc:state" value="Active"/>
											<xes:string key="concept:name" value="phaseOut"/>
											<xes:string key="sc:event" value="phaseOut"/>
											<xes:string key="sc:target" value="PhasingOut"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T08:30:00.500+02:00"/>
											<xes:string key="sc:state" value="PhasingOut"/>
											<xes:string key="concept:name" value="cancel"/>
											<xes:string key="sc:event" value="cancel"/>
											<xes:string key="sc:target" value="Cancelled"/>
										</xes:event>
										<xes:event>
											<xes:date key="time:timestamp" value="2016-01-01T09:00:00.500+02:00"/>
											<xes:string key="sc:state" value="Cancelled"/>
											<xes:string key="concept:name" value="discontinue"/>
											<xes:string key="sc:event" value="discontinue"/>
											<xes:string key="sc:target" value="Discontinued"/>
										</xes:event>
									</xes:trace>
								</xes:log>
							</sc:data>
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
              <sc:state id="Discontinued" mba:isArchiveState="true"/>
						</sc:state>
					</sc:scxml>
          
return sc:isEveryOriginalStateInRefined($statesOriginal, $scxmlRentalRefinedStateHasWrongAncestor) 
          
 