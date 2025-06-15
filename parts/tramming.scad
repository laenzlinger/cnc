include <BOSL2/screws.scad>
include <BOSL2/std.scad>

diff()
{
    cube([ 200, 80, 15 ], anchor = [ 0, 0 ]) attach(TOP)
    {
        back(20.5) left(80) sbr12();
        fwd(20.5) left(80) sbr12();
        back(20.5) right(80) sbr12();
        fwd(20.5) right(80) sbr12();
        left(30) zmount();
        right(50) zmount();
    }
}

module sbr12()
{
    fwd(13) left(14) screw_hole("M5x1,15", head = "button", anchor = TOP);
    fwd(13) right(14) screw_hole("M5x1,15", head = "button", anchor = TOP);
    back(13) left(14) screw_hole("M5x1,15", head = "button", anchor = TOP);
    back(13) right(14) screw_hole("M5x1,15", head = "button", anchor = TOP);
    // down(28) cube([ 40, 39, 27.6 ], anchor = [ 0, 0 ]);
}

module zmount()
{
    fwd(30) screw_hole("M5x1,15", anchor = TOP);
    back(30) screw_hole("M5x1,15", anchor = TOP);
}
