(:~

 : --------------------------------
 : MBAse: An MBA database in XQuery
 : --------------------------------
  
 : Copyright (C) 2015 Christoph Schütz
   
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
  
 : Custom SCXML interpreter extension that defines multilevel predicates
 : for the use in dynamically evaluated SCXML expressions.
 
 : @author Christoph Schütz
 :)
module namespace scx='http://www.w3.org/2005/07/scxml/extension/';

declare function scx:importModules() as xs:string {
  let $importMbaNamespace :=
    'import module namespace mba = "http://www.dke.jku.at/MBA"; '
  
  let $importSyncNamespace :=
    'import module namespace sync = "http://www.dke.jku.at/MBA/Synchronization"; '
  
  return $importMbaNamespace ||
         $importSyncNamespace
};

declare function scx:builtInFunctionDeclarations() as xs:string {
  
  let $declareMba :=
    'let $mba := mba:getMBA($_x/db, $_x/collection, $_x/name) '
  
  let $inFunction :=
    'let $_in := function($stateId) { ' ||
      'fn:exists($_x/currentStatus/state[@ref=$stateId])' || 
    '} '
  
  let $syncEveryDescendantAtLevelIsInState :=
    'let $_everyDescendantAtLevelIsInState := ' ||
      'sync:everyDescendantAtLevelIsInState($mba, ?, ?) '
  
  let $syncSomeDescendantAtLevelIsInState :=
    'let $_someDescendantAtLevelIsInState := ' ||
      'sync:someDescendantAtLevelIsInState($mba, ?, ?) '
  
  let $syncEveryDescendantAtLevelSatisfies :=
    'let $_everyDescendantAtLevelSatisfies := ' ||
      'sync:everyDescendantAtLevelSatisfies($mba, ?, ?) '
  
  let $syncSomeDescendantAtLevelSatisfies :=
    'let $_someDescendantAtLevelSatisfies := ' ||
      'sync:someDescendantAtLevelSatisfies($mba, ?, ?) '
  
  let $syncAncestorAtLevelInState :=
    'let $_ancestorAtLevelIsInState := ' ||
      'sync:ancestorAtLevelIsInState($mba, ?, ?) '
      
  let $syncAncestorAtLevelSatisfies :=
    'let $_ancestorAtLevelSatisfies := ' ||
      'sync:ancestorAtLevelSatisfies($mba, ?, ?) '
  
  return $declareMba ||
         $inFunction ||
         $syncEveryDescendantAtLevelIsInState ||
         $syncSomeDescendantAtLevelIsInState ||
         $syncEveryDescendantAtLevelSatisfies ||
         $syncSomeDescendantAtLevelSatisfies ||
         $syncAncestorAtLevelInState ||
         $syncAncestorAtLevelSatisfies
};