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
  
 : @author Christoph Schütz
 : @author Michael Weichselbaumer
 :)
module namespace reflection='http://www.dke.jku.at/MBA/Reflection';

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'mba.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'scxml.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx.xqm';
import module namespace scc = "http://www.w3.org/2005/07/scxml/consistency/" at 'scxml_consistency.xqm';

declare updating function reflection:setActive($mba  as element(),
                                               $name as xs:string) {
  ()
};


declare function reflection:getRefinedState($state as element(), $subState as element()) as element()* {
  let $mba := $state/ancestor::mba:mba

    return if (not(mba:getDescendants($mba))) then (
      let $originalScxml := $state/ancestor::sc:scxml

      let $refinedScxml := copy $c := $originalScxml modify (
        let $stateCopy := $c//sc:state[@id=$state/@id/data()]
        return insert node $subState into $stateCopy
      ) return $c

      return if (scc:isBehaviorConsistentSpecialization($originalScxml, $refinedScxml)) then (
          $refinedScxml//sc:state[@id=$state/@id/data()]
      ) else (
            error(QName('http://www.dke.jku.at/MBA/err',
                        'RefineStateConsistencyCheck'),
                        'State cannot be refined because this would result in behavior consistency violation')
      )
    ) else (
      error(QName('http://www.dke.jku.at/MBA/err',
              'RefineStateDescendantCheck'),
              concat('State cannot be refined because MBA ', $mba/@name/data(), ' has already descendants'))
    )
};

declare updating function reflection:refineState($state as element(), $subState as element()) {
    let $refinedState := reflection:getRefinedState($state, $subState)
    return replace node $state with $refinedState
};


