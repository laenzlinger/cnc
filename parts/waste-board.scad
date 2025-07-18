include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;
motor_cutout = 135;
difference()
{
    plate();
    left(200 - motor_cutout / 2) down(3) cube([ motor_cutout + 0.1, 70, 12.1 ], anchor = [ 0, 0 ]);
    left(60) back(74) sbr12();
    right(60) back(74) sbr12();
    left(60) fwd(74) sbr12();
    right(60) fwd(74) sbr12();
    nut_housing();
}

module plate()
{
    cube([ 400, 240, 18 ], anchor = [ 0, 0 ]);
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
    cylinder(d = 5.5, h = 30, anchor = [ 0, 0 ]);
    up(6) cylinder(d = 10, h = 20, anchor = [ 0, 0, 0 ]);
}
