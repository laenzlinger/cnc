// a jig to hold a dial indicator in place
// to adjust the x-axes rails (SBR 12)

include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;

diff()
{
    cube([ 150, 40, 10 ], anchor = [ 0, 0 ])
    {
        attach(TOP) right(55) sbr12();

        xrot(90) left(65) up(15) screw_hole("M5,15", thread = true);
        xrot(90) left(55) up(15) screw_hole("M5,15", thread = true);
        xrot(90) left(45) up(15) screw_hole("M5,15", thread = true);
        xrot(90) left(35) up(15) screw_hole("M5,15", thread = true);
        xrot(90) left(25) up(15) screw_hole("M5,15", thread = true);
    }
}

module sbr12()
{
    fwd(13) left(14) screw_hole("M5,15", anchor = TOP);
    fwd(13) right(14) screw_hole("M5,15", anchor = TOP);
    back(13) left(14) screw_hole("M5,15", anchor = TOP);
    back(13) right(14) screw_hole("M5,15", anchor = TOP);
    //  down(24) cube([ 40, 39, 27.6 ], anchor = [ 0, 0 ]);
}
