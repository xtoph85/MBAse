xquery version "3.0";

(:~
: User: mwe
: Date: 26.12.2015
: Time: 12:42
: To change this template use File | Settings | File Templates.
:)

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';


declare variable $db := 'myMBAse';
declare variable $collection := 'JohannesKeplerUniversity';
declare variable $mbaName := 'SocialAndEconomicSciences';

let $mba := mba:getMBA($db, $collection, $mbaName)

let $scxml := mba:getSCXML($mba)

return $scxml