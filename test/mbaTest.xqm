xquery version "3.0";

(:~
: User: mwe
: Date: 09.03.2016
: Time: 10:37
: To change this template use File | Settings | File Templates.
:)



module namespace mbaTest = "http://www.dke.jku.at/MBA/test";

import module namespace mba = 'http://www.dke.jku.at/MBA' at 'D:/workspaces/master/MBAse/modules/mba.xqm';
import module namespace functx = 'http://www.functx.com' at 'D:/workspaces/master/MBAse/modules/functx.xqm';
import module namespace sc='http://www.w3.org/2005/07/scxml' at 'D:/workspaces/master/MBAse/modules/scxml.xqm';


declare %unit:test function mbaTest:void() { () };

declare %unit:test('expected', "err:XPTY0004") function mbaTest:add() {
    123 + 'strings and integers cannot be added'
};