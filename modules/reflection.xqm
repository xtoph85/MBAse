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
 :)
module namespace reflection='http://www.dke.jku.at/MBA/Reflection';

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'mba.xqm';
import module namespace sc = 'http://www.w3.org/2005/07/scxml' at 'scxml.xqm';
import module namespace functx = 'http://www.functx.com' at 'functx.xqm';

declare updating function reflection:setActive($mba  as element(),
                                               $name as xs:string) {
  ()
};
