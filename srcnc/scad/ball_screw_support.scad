include <NopSCADlib/utils/core/core.scad>
use <NopSCADlib/vitamins/ball_bearing.scad>
use <NopSCADlib/vitamins/screw.scad>

function bf_size(type) = [ type[3], type[4], type[2] ]; //! Size of BF suport
function bf_center_height(type) = type[5];              //! Denter height
function bf_shoulder_height(type) = type[7];            //! Shoulder height
function bf_screw_separation_x(type) = type[9];         //! Screw separation in X direction
function bf_screw_counter_bore_depth(type) = type[13];  //! Counter bore depth
function bf_bearing_type(type) = type[14];              //! Bearing type
function bf_screw_type(type) = type[15];                //! Mounting screw type

ball_screw_support_color = grey(90);

module floating_ball_screw_support(type)
{ //! Draw the specified BF ball_screw_support
    vitamin(str("floating_ball_screw_support(", type[0], "): ", type[0], " floating ball screw support"));

    d1 = type[1];
    L = type[2];
    B = type[3];
    H = type[4];
    h = bf_center_height(type);
    B1 = type[6];
    H1 = bf_shoulder_height(type);
    E = type[8];
    P = bf_screw_separation_x(type);
    d2 = type[10];
    X = type[11];
    Y = type[12];
    Z = bf_screw_counter_bore_depth(type);

    bearing = bf_bearing_type(type);
    chamfer = 1.5;

    color(ball_screw_support_color)
    {
        render() difference()
        {
            linear_extrude(L, center = true, convexity = 2)
            {
                difference()
                {
                    // center section with bearing hole
                    translate([ 0, -h ]) for (m = [ 0, 1 ]) mirror([ m, 0, 0 ]) union()
                    {
                        square([ B / 2, H1 ]);
                        square([ B1 / 2, H ]);
                    }
                    // parallel holes
                    circle(d = bb_diameter(bearing));
                    for (x = [ -P / 2, P / 2 ])
                        for (y = [ 0, -E ])
                            translate([ x, y ]) circle(d = d2);
                }
            }
            // bolt holes
            for (x = [ -P / 2, P / 2 ])
            {
                translate([ x, -h ]) rotate([ -90, 0, 0 ]) cylinder(d = X, h = H1);
                translate([ x, -h + H1 - Z ]) rotate([ -90, 0, 0 ]) cylinder(d = Y, h = Z);
            }
        }
    }
}

module floating_ball_screw_support_hole_positions(type)
{ //! Place children at hole positions
    E = bf_screw_separation_x(type);
    for (x = [ -E, E ])
        translate([ x / 2, 0, 0 ]) children();
}

module floating_ball_screw_support_assembly(type, screw_type)
{ //! Assembly with screws in place

    Z = bf_screw_counter_bore_depth(type);
    H1 = bf_shoulder_height(type);
    h = bf_center_height(type);
    bearing = bf_bearing_type(type);
    floating_ball_screw_support(type);
    ball_bearing(bearing);
    screw_length = H1 - Z + 10;
    screw_type = is_undef(screw_type) ? bf_screw_type(type) : screw_type;
    translate([
        0,
        H1 - h - Z,
        0,
    ]) floating_ball_screw_support_hole_positions(type) rotate([ -90, 0, 0 ]) screw(screw_type, screw_length);
}
