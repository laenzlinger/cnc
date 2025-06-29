include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;

difference()
{
    cuboid([ 16, 80, 12 ], anchor = [ 0, 0 ], rounding = 1, edges = "Z");
    fwd(20) cuboid([ 6.2, 27, 14 ], anchor = [ 0, 0 ], rounding = 3);
    back(15) cuboid([ 6.2, 27, 14 ], anchor = [ 0, 0 ], rounding = 3);
    fwd(5) up(3) cube([ 25, 72, 10 ], anchor = [ 0, 0 ]);
}
