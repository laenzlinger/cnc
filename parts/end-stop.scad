include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;

difference()
{
    cuboid([ 20, 60, 8 ], anchor = [ 0, 0 ], rounding = 2);
    cube([ 5.5, 40, 10 ], anchor = [ 0, 0 ]);
    fwd(20) cylinder(d = 5.5, 10, center = true);
    back(20) cylinder(d = 5.5, 10, center = true);
}
