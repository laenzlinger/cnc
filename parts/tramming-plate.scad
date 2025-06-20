include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;

diff()
{
    cube([ 80, 200, 15 ], anchor = [ 0, 0 ]) attach(TOP)
    {
        left(20.5) back(80) sbr12();
        right(20.5) back(80) sbr12();
        left(20.5) fwd(80) sbr12();
        right(20.5) fwd(80) sbr12();
        back(30) zmount();
        fwd(50) zmount();
        nut_housing();
    }
}

module sbr12()
{
    // see https://cnc4you.co.uk/resources/SBRxxUU.pdf
    W = 40;
    M = 39;
    G = 27.6;
    J = 28;
    K = 26;

    width = K / 2;
    height = J / 2;

    left(width) fwd(height) mounting_hole();
    right(width) fwd(height) mounting_hole();
    left(width) back(height) mounting_hole();
    right(width) back(height) mounting_hole();
    // down(28) cube([ M, W, G ], anchor = [ 0, 0 ]);
}

module mounting_hole()
{
    screw_hole("M5,18", head = "button", anchor = TOP);
}

module nut_housing()
{
    width = 24 / 2;
    height = 35 / 2;
    left(width) fwd(height) mounting_hole();
    right(width) fwd(height) mounting_hole();
    left(width) back(height) mounting_hole();
    right(width) back(height) mounting_hole();
}

module zmount()
{
    left(30) screw_hole("M6,18", anchor = TOP);
    right(30) screw_hole("M6,18", anchor = TOP);
}
