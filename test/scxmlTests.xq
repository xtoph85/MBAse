import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';
import module namespace scx='http://www.w3.org/2005/07/scxml/extension/' at 'D:/workspaces/master/MBAse/modules/scxml_extension.xqm';


declare variable $db := 'myMBAse';
declare variable $collectionName := 'parallelHomogenous';

let $_event := <test></test>

let $scxml1 := <sc:scxml name="School">
            <sc:datamodel>
              <sc:data id="offeredDegrees"/>
            </sc:datamodel>
            <sc:initial>
              <sc:transition target="Existing"/>
            </sc:initial>
            <sc:state id="Existing">
              <sc:transition event="addDegree" cond="not $offeredDegrees/degree[name=$_event/data/text()]">
                <sc:assign location="$offeredDegrees" expr="&lt;degree name='{$_event/data/text()}'/&gt;" type="lastchild"/>
              </sc:transition>
              <sc:transition event="removeDegree">
                <sc:assign location="$offeredDegrees/degree[name=$_event/data/text()]" type="delete"/>
              </sc:transition>
              <sc:transition event="addProgram">
              </sc:transition>
              <sc:transition event="closeDown" target="Defunct"/>
            </sc:state>
            <sc:state id="Defunct"/>
          </sc:scxml>

let $scxml2 := <sc:scxml name="School">
            <sc:datamodel>
              <sc:data id="offeredDegrees"/>
            </sc:datamodel>
            <sc:initial>
              <sc:transition target="Existing"/>
            </sc:initial>
            <sc:state id="Existing">
              <sc:transition event="addDegree" cond="not $offeredDegrees/degree[name=$_event/data/text()]">
                <sc:assign location="$offeredDegrees" expr="&lt;degree name='{$_event/data/text()}'/&gt;" type="lastchild"/>
              </sc:transition>
              <sc:transition event="removeDegree">
                <sc:assign location="$offeredDegrees/degree[name=$_event/data/text()]" type="delete"/>
              </sc:transition>
              <sc:transition event="addProgram">
              </sc:transition>
              <sc:transition event="closeDown" target="Defunct"/>
            </sc:state>
            <sc:state id="Defunct"/>
          </sc:scxml>
          
let $in-xml :=
<authors>
   <author>
      <fName>Kate</fName>
      <lName>Jones</lName>
   </author>
   <author>
      <fName>John</fName>
      <lName>Doe</lName>
   </author>
</authors>

let $anAuthor :=
<author>
   <fName>Kate</fName>
   <lName>Jones</lName>
</author>
          
(: Diese Funktion bringt leider nix weil sie nicht den Inhalt sondern die Node-Identity zur Überprüfung heranzieht:)      
return functx:sequence-node-equal-any-order(
     $in-xml/author[1],$anAuthor)