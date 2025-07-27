$pp1_colour = "grey"; // Override any global defaults here if required, see NopSCADlib/global_defs.scad.

//! Small rigid CNC.

include <NopSCADlib/lib.scad> // Includes all the vitamins and utilities in NopSCADlib but not the printed parts.
include <NopSCADlib/vitamins/sbr_rails.scad>
include <ball_screw_supports.scad>
include <linear_guide_tables.scad>
use <NopSCADlib/vitamins/sbr_rail.scad>
use <ball_screw_support.scad>
use <linear_guide_table.scad>

SFU1204 = [
    "SFU1204", "Leadscrew Nut for SFU1204", 12, 22, 35, 42, 8, 0, 6, 4.5, 32 / 2, M4_cap_screw, 4, 10, 30, "#DFDAC5"
];

LNH = [ "LNH", "Leadscrew Nut Housing", 30, 50, 36, -1, 24, 35, M5_cap_screw, 15, SFU1204, 15 ];
LM12UUOP = [ "LM12UUOP", 30, 21, 12, 1.3, 20.0, 23.0, 8 ];

//  see https://cnc4you.co.uk/resources/SBRxxUU.pdf
//                T  h     H   W   M   G     J   K   A  S1            I   LB                         S2 S2L
SBR12UU =
    [ "SBR12UU", 12, 22.5, 40, 40, 39, 27.6, 28, 26, 8, M5_cap_screw, 10, LM12UUOP, circlip_21i, 0, M5_grub_screw, 5 ];

//                    d  h     B   T  carriage P    S2            C   S3            S3L
SBR12S = [ "SBR12S", 12, 22.5, 30, 4.5, SBR12UU, 100, M4_cap_screw, 22, M4_cap_screw, 16 ];

Chipboard40 = [ "Chipboard40", "Chipboard", 40, mdf_colour, false ];
MDF15 = [ "MDF15", "Sheet MDF", 15, mdf_colour, false ];
SC_8x8_flex = [ "SC_8x8_flex", 25, 19, 8, 8, true ];

yaxis_length = 550;
yrail_separation = 180;
ycarriage_separation = 120;
yplate_thickness = 15;
yplate_length = yaxis_length + 30;

xaxis_length = 350;
xrail_separation = 160;
xcarriage_separation = 40;
xplate_thickness = 40;
xplate_length = xaxis_length + 10;

side_plate_thickness = 40;

function bf_pos(l) = l / 2 - 10;
function bk_pos(l) = l / 2 - 41;

module yaxis_assembly() assembly("yaxis")
{
    axis(yaxis_length, yrail_separation, ycarriage_separation, 18, yplate_thickness);
    translate([ 0, 0, -yplate_thickness / 2 ]) explode(-50) render_2D_sheet(MDF15) yplate_dxf();
    translate([ 0, 0, 40 + 9 ]) rotate([ 0, 0, 90 ]) render_sheet(MDF18) waste_board_stl();
}

module xaxis_assembly() assembly("xaxis")
{
    rotate([ 0, 0, -90 ]) axis(xaxis_length, xrail_separation, xcarriage_separation, 45, xplate_thickness);
    translate([ 0, 0, -xplate_thickness / 2 ]) explode(-50) render_2D_sheet((Chipboard40)) xplate_dxf();
    translate([ 0, 0, 40 + 7.5 ]) render_sheet(MDF15) zplate_stl();
    rotate([ 0, 0, 90 ]) translate([ 0, 0, 40 + 15 ]) explode(200) zaxis_assembly();
}

module zaxis_assembly() assembly("zaxis")
{
    {
        bsh = lgt_ballscrew_height(SGX_5080);
        linear_guide_table_assembly(SGX_5080);
        motor = lgt_motor_pos(SGX_5080);
        translate([ motor - 5, 0, bsh ]) rotate([ 0, -90, 0 ])
        {
            explode(-80) NEMA(NEMA23_51);
            translate([ 0, 0, 26 ]) explode(-50) shaft_coupling(SC_8x8_flex);
        }
    }
}

module axis(length, rail_separation, carriage_separation, motor_separation, board_thickness)
{
    translate([ 0, 0, bf_center_height(BF10) ]) rotate([ 90, -90, 0 ])
    {
        leadscrew(12, length, 4, 1);
        leadnuthousing(LNH);
        nut = leadnuthousing_nut(LNH);
        rotate([ 0, 90, 0 ]) translate([ 0, 0, leadnuthousing_height(LNH) / 2 - 1.6 ]) explode(10)
            nut_housing_adapter_stl();
        translate_z(leadnuthousing_height(LNH) / 2)
        {
            leadnut(nut);
            leadnuthousing_nut_screw_positions(LNH) screw(leadnut_screw(nut), leadnuthousing_nut_screw_length(LNH));
        }
        translate([ 0, 0, bf_pos(length) ]) rotate([ 0, 0, -90 ])
        {
            bfh = bf_shoulder_height(BF10);
            floating_ball_screw_support_assembly(BF10, M5_cap_screw, board_thickness + bfh);
            translate([ 0, -board_thickness - bf_center_height(BF10), 0 ])
                floating_ball_screw_support_hole_positions(BF10) rotate([ 90, 0, 0 ]) explode(100)
                    nut_and_washer(M5_nut);
        }
        translate([ 0, 0, -bk_pos(length) ])
        {
            bkh = bk_shoulder_height(BK10);
            rotate([ 180, 0, 90 ]) fixed_ball_screw_support_assembly(BK10, M5_cap_screw, board_thickness + bkh);
            rotate([ 90, 0, -90 ]) translate([ 0, 0, (board_thickness + bk_center_height(BK10)) ])
                fixed_ball_screw_support_hole_positions(BK10) explode(100) nut_and_washer(M5_nut);
        }
        translate([ 0, 0, -length / 2 - motor_separation ])
        {
            explode(-100) NEMA(NEMA23_51);
            translate([ 0, 0, 18 ]) explode(-20) shaft_coupling(SC_8x8_flex);
        };
    }
    for (rs = [ rail_separation, -rail_separation ])
        translate([ rs / 2, 0, sbr_rail_center_height(SBR12S) ]) rail(length, carriage_separation, board_thickness);
}

module rail(length, carriage_separation, board_thickness)
{
    rotate([ 90, 180, 0 ])
    {
        sheet = 8;
        rail = SBR12S;
        carriage = sbr_rail_carriage(rail);
        sbr_rail(rail, length);
        screw = sbr_rail_screw(rail);
        // carriages
        for (cs = [ carriage_separation, -carriage_separation ])
            translate([ 0, 0, cs / 2 ]) sbr_bearing_block_assembly(carriage, sheet);
        // screw down the rail
        sbr_screw_positions(rail, length) rotate([ 90, 0, 0 ])
        {
            explode(80) screw(screw, board_thickness + 10);
            translate([ 0, 0, -(board_thickness + 4) ]) rotate([ 0, 180, 0 ]) explode(150) nut_and_washer(M4_nut);
        }
    }
}

module yplate_dxf() dxf("yplate")
{
    difference()
    {
        sheet_2D(MDF15, xplate_length - 4, yplate_length);
        yplate_mounting_screw_positions() circle(4);
        axis_holes(yrail_separation, yaxis_length);
    }
}

module xplate_dxf() dxf("xplate")
{
    difference()
    {
        sheet_2D(Chipboard40, xplate_length, 200);
        rotate([ 0, 0, -90 ]) axis_holes(xrail_separation, xaxis_length);
        zplate_mounting_screw_positions() circle(6);
    }
}

module axis_holes(rail_separation, axis_length)
{
    translate([ 0, -bf_pos(axis_length), 0 ]) floating_ball_screw_support_hole_positions(BF10) circle(3);
    translate([ 0, bk_pos(axis_length), 0 ]) fixed_ball_screw_support_hole_positions(BK10) circle(3);
    for (rs = [ -rail_separation, rail_separation ])
        translate([ rs / 2, 0, 0 ]) projection() rotate([ 90, 0, 0 ]) sbr_screw_positions(SBR12S, axis_length)
            rotate([ 90, 0, 0 ]) cylinder(r = 3, h = 40);
}

module yplate_mounting_screw_positions()
{
    rectangular_mounting_screw_positions(280, 480) children();
}

module rectangular_mounting_screw_positions(x, y)
{
    xh = x / 2;
    yh = y / 2;
    translate([ xh, yh, 0 ]) children();
    translate([ -xh, yh, 0 ]) children();
    translate([ xh, -yh, 0 ]) children();
    translate([ -xh, -yh, 0 ]) children();
}

module nut_housing_adapter_stl() stl("nut_housing_adapter")
{
    correction = -0.2;
    height = 40 - (22 + 15) + correction;

    difference()
    {
        cube([ 36, 50, height ], center = true);
        leadnuthousing_screw_positions(LNH) cylinder(r = 2.7, h = 10, center = true);
    }
}

module zplate_stl() stl("zplate")
{
    difference()
    {
        thickness = 15;
        sheet(MDF15, 80, 200);
        // leadnut housing holes
        lnh_screw = leadnuthousing_mount_screw(LNH);
        leadnuthousing_screw_positions(LNH) sunk_screw_hole(thickness, lnh_screw);
        // carriage holes
        carriage = sbr_rail_carriage(SBR12S);
        for (x = [ 1, -1 ], y = [ 1, -1 ])
            rotate([ 90, 0, 0 ]) translate([ x * xcarriage_separation / 2, 18, y * xrail_separation / 2 ])
                sbr_bearing_block_hole_positions(carriage) sunk_screw_hole(thickness, sbr_screw(carriage));
        // mounting holes
        zplate_mounting_screw_positions()
            cylinder(h = thickness + 1, r = screw_clearance_radius(M6_cap_screw), center = true);
    }
}

module waste_board_stl() stl("waste_board")
{
    difference()
    {
        sh = MDF18;
        thickness = sheet_thickness(sh);
        sheet(sh, 400, 240);
        // leadnut housing holes
        lnh_screw = leadnuthousing_mount_screw(LNH);
        leadnuthousing_screw_positions(LNH) sunk_screw_hole(thickness, lnh_screw);
        // carriage holes
        carriage = sbr_rail_carriage(SBR12S);
        for (x = [ 1, -1 ], y = [ 1, -1 ])
            rotate([ 90, 0, 0 ]) translate([ x * ycarriage_separation / 2, 18, y * yrail_separation / 2 ])
                sbr_bearing_block_hole_positions(carriage) sunk_screw_hole(thickness, sbr_screw(carriage));
        // motor resess
        resess_width = NEMA_width(NEMA23_51) + 10;
        resess_depth = 10; // FIXME calculate this from the motor height
        translate([ yaxis_length / 2 - 80, 0, -thickness + resess_depth ])
            cube([ 200, resess_width, thickness ], center = true);
    }
}

// screw hole down to 1/3 of the thickness
module sunk_screw_hole(thickness, screw)
{
    remainder = 5;
    cylinder(h = thickness + remainder, r = screw_clearance_radius(screw), center = true);
    translate([ 0, 0, 5 ]) cylinder(h = thickness, r = screw_head_radius(screw) + 0.3, center = true);
}

module zplate_mounting_screw_positions()
{
    rectangular_mounting_screw_positions(60, 100) children();
}

module frame_assembly() assembly("Frame")
{
    screw_length = side_plate_thickness + 15;
    side_distance = (xplate_length + side_plate_thickness) / 2;
    translate([ side_distance, 0, 0 ]) rotate([ 0, -90, 180 ]) explode(150, true)
    {
        render_2D_sheet((Chipboard40)) frame_right_side_dxf();
        frame_side_screw_positions()
        {
            translate([ 0, 0, 20 ])
            {
                explode(100) screw_and_washer(M6_cap_screw, screw_length);
                translate([ 0, 0, -40 ]) explode(-50) threaded_insert(M6x15);
            }
        }
    }
    translate([ -side_distance, 0, 0 ]) rotate([ 0, -90, 180 ]) explode(-150, true)
    {
        render_2D_sheet((Chipboard40)) frame_left_side_dxf();
        frame_side_screw_positions()
        {
            translate([ 0, 0, -20 ])
            {
                rotate([ 0, 180, 0 ])
                {
                    explode(100) screw_and_washer(M6_cap_screw, screw_length);
                    translate([ 0, 0, -40 ]) explode(-50) threaded_insert(M6x15);
                }
            }
        }
    }

    translate([ -0, 0, -180 ]) render_2D_sheet(Chipboard40) frame_bottom_side_dxf();
}

module frame_left_side_dxf() dxf("frame_left_side")
{
    difference()
    {
        sheet_2D(Chipboard40, 400, 360);
        frame_side_screw_positions() circle(4);
    }
}

module frame_right_side_dxf() dxf("frame_right_side")
{
    difference()
    {
        sheet_2D(Chipboard40, 400, 360);
        frame_side_screw_positions() circle(4);
        translate([ 100, -118.5, 0 ]) circle(20);
    }
}

module frame_bottom_side_dxf() dxf("frame_bottom_side")
{
    difference()
    {
        sheet_2D(Chipboard40, xaxis_length + 10, yplate_length);
    }
}

module frame_side_screw_positions()
{
    for (i = [0:1:4])
        translate([ -180, -160 + i * 80, 0 ]) children();
    for (i = [0:1:2])
        translate([ 20 + i * 80, -160, 0 ]) children();
}
//! Assembly instructions in Markdown format in front of each module that makes an assembly.
module main_assembly() assembly("main")
{
    frame_assembly();
    translate([ 0, 0, -145 ]) explode(50, true)
    {
        yaxis_assembly();
        yplate_mounting_screw_positions()
        {
            explode(50) screw_and_washer(M6_cap_screw, 20);
            translate([ 0, 0, -15 ]) explode(-20) threaded_insert(M6x15);
        }
    }
    rotate([ 90, 0, 0 ]) translate([ 0, 100, -140 ]) explode(-150) xaxis_assembly();
}

if ($preview)
    main_assembly();
// yaxis_assembly();
// xaxis_assembly();
// zaxis_assembly();
// zplate_stl();
//  waste_board_stl();
