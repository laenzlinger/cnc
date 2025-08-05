include <BOSL2/std.scad>

$fn = 100;

axis = [ [ -2, "X" ], [ -1, "Y" ], [ 0, "Z" ], [ 1, "Y2" ], [ 2, "A" ] ];

difference()
{
    union()
    {
        cuboid([ 118.5, 118.5, 3 ], anchor = [ 0, 0 ], rounding = 3, edges = "Z");
        for (a = axis)
        {
            translate([ 20 * a[0], 0, 1.5 ]) linear_extrude(1) text(a[1], halign = "center", valign = "center");
        }
    }
    for (x = [ -1, 1 ], y = [ -1, 1 ])
    {
        translate([ x * 52.05, y * 52.05 ]) cylinder(d = 5.2, h = 10, center = true);
    }
    for (x = [-2:2], y = [ -1, 1 ])
    {
        translate([ x * 20, y * 20 ]) cylinder(d = 12.2, h = 10, center = true);
    }
}
