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