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