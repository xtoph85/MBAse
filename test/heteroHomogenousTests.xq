import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';


declare variable $db := 'myMBAse';
declare variable $collectionName := 'heterohomogenousParallel';



(: Create a dedicated collection for heterohomogenous MBA's    
mba:createCollection($db, $collectionName)  :)

