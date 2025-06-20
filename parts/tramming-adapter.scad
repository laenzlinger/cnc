include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;

diff()
{
    height = (32.5 + 15) - 40;
    // see https://cnc4you.co.uk/resources/SBRxxUU.pdf
    cube([ 36, 50, height ], anchor = [ 0, 0 ]) attach(TOP)
    {
        nut_housing();
    }
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

module mounting_hole()
{
    screw_hole("M5,18", anchor = TOP);
}
