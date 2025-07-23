$pp1_colour = "grey"; // Override any global defaults here if required, see NopSCADlib/global_defs.scad.

//! Small rigid CNC.

include <NopSCADlib/lib.scad> // Includes all the vitamins and utilities in NopSCADlib but not the printed parts.
include <NopSCADlib/vitamins/sbr_rails.scad>
include <ball_screw_supports.scad>
use <NopSCADlib/vitamins/sbr_rail.scad>
use <ball_screw_support.scad>

SFU1204 = [
    "SFU1204", "Leadscrew nut for SFU1204", 12, 22, 35, 42, 8, 0, 6, 4.5, 32 / 2, M4_cap_screw, 4, 10, 30, "#DFDAC5"
];

LNH = [ "LNH", "Lead Screw Nut Housing", 30, 50, 36, -1, 24, 35, M5_cs_cap_screw, 15, SFU1204, 15 ];
LM12UUOP = [ "LM12UUOP", 30, 21, 12, 1.3, 20.0, 23.0, 8 ];

//                T  h   H   W   M   G     J   K   A  S1            I   LB                         S2 S2L
SBR12UU =
    [ "SBR12UU", 12, 25, 40, 41, 40, 27.6, 28, 26, 9, M5_cap_screw, 12, LM12UUOP, circlip_21i, 0, M5_grub_screw, 5 ];

//                    d  h   B   T  carriage P    S2            C   S3            S3L
SBR12S = [ "SBR12S", 12, 19, 32, 4, SBR12UU, 150, M5_cap_screw, 22, M4_cap_screw, 13 ];

Chipboard40 = [ "Chipboard40", "Chipboard", 40, mdf_colour, false ];
MDF15 = [ "MDF15", "Sheet MDF", 15, mdf_colour, false ];
SC_8x8_flex = [ "SC_8x8_flex", 25, 19, 8, 8, true ];

yaxis_length = 550;

function bf_pos(l) = l / 2 - 10;
function bk_pos(l) = l / 2 - 41;

module yaxis_assembly() assembly("yaxis")
{
    translate([ 0, 0, 16.5 ]) rotate([ 0, 0, 90 ]) explode(10) nut_housing_adapter_stl();
    rotate([ 90, -90, 0 ])
    {
        leadscrew(12, yaxis_length, 4, 1);
        leadnuthousing(LNH);
        nut = leadnuthousing_nut(LNH);
        translate_z(leadnuthousing_height(LNH) / 2)
        {
            leadnut(nut);
            leadnuthousing_nut_screw_positions(LNH) screw(leadnut_screw(nut), leadnuthousing_nut_screw_length(LNH));
        }
        translate([ 0, 0, bf_pos(yaxis_length) ]) rotate([ 0, 0, -90 ]) floating_ball_screw_support_assembly(BF10);
        translate([ 0, 0, -bk_pos(yaxis_length) ]) rotate([ 180, 0, --90 ]) fixed_ball_screw_support_assembly(BK10);
        translate([ 0, 0, -yaxis_length / 2 - 20 ])
        {
            explode(-100) NEMA(NEMA23_51);
            translate([ 0, 0, 18 ]) explode(-20) shaft_coupling(SC_8x8_flex);
        };
    }
    translate([ 80, 0, 0 ]) yrail();
    translate([ -80, 0, 0 ]) yrail();
    translate([ 0, 0, -26.5 ])
    {
        explode(-50) render_2D_sheet(MDF15) yplate_dxf();
        yplate_mounting_screw_positions()
        {
            translate([ 0, 0, 7.5 ])
            {
                explode(40) screw_and_washer(M6_cap_screw, 20);
                translate([ 0, 0, -15 ]) explode(-100) threaded_insert(M6x15);
            }
        }
    }
}

module yrail()
{
    rotate([ 90, 180, 0 ])
    {
        length = yaxis_length;
        sheet = 8;
        rail = SBR12S;
        carriage = sbr_rail_carriage(rail);
        sbr_rail(rail, length);
        screw = sbr_rail_screw(rail);
        translate([ 0, 0, 60 ]) sbr_bearing_block_assembly(carriage, sheet);
        translate([ 0, 0, -60 ]) sbr_bearing_block_assembly(carriage, sheet);
        sbr_screw_positions(rail, length) rotate([ 90, 0, 0 ])
        {
            explode(20) screw_and_washer(screw, 18);
            explode(-220) nut(M5_nut);
        }
    }
}

module yplate_dxf() dxf("yplate")
{
    difference()
    {
        sheet_2D(MDF15, 356, 580);
        yplate_mounting_screw_positions() circle(4);
        translate([ 0, -bf_pos(yaxis_length), 0 ]) floating_ball_screw_support_hole_positions(BF10) circle(3);
        translate([ 0, bk_pos(yaxis_length), 0 ]) fixed_ball_screw_support_hole_positions(BK10) circle(3);
        translate([ -80, 0, 0 ]) projection() rotate([ 90, 0, 0 ]) sbr_screw_positions(SBR12S, 550) rotate([ 90, 0, 0 ])
            cylinder(r = 3, h = 10);
        translate([ 80, 0, 0 ]) projection() rotate([ 90, 0, 0 ]) sbr_screw_positions(SBR12S, 550) rotate([ 90, 0, 0 ])
            cylinder(r = 3, h = 10);
    }
}

module yplate_mounting_screw_positions()
{
    x = 140;
    y = 250;
    translate([ x, y, 0 ]) children();
    translate([ -x, y, 0 ]) children();
    translate([ x, -y, 0 ]) children();
    translate([ -x, -y, 0 ]) children();
}

module nut_housing_adapter_stl() stl("nut_housing_adapter")
{
    correction = -0.2;
    height = 40 - (22 + 15) + correction;
    //  see https://cnc4you.co.uk/resources/SBRxxUU.pdf

    difference()
    {
        cube([ 36, 50, height ], center = true);
        leadnuthousing_screw_positions(LNH) cylinder(r = 2.7, h = 10, center = true);
    }
}

module frame_assembly() assembly("Frame")
{
    screw_length = 55;
    translate([ 200, 0, 0 ]) rotate([ 0, -90, 180 ]) explode(50)
    {
        render_2D_sheet((Chipboard40)) frame_right_side_dxf();
        frame_side_screw_positions()
        {
            translate([ 0, 0, 20 ])
            {
                screw_and_washer(M6_cap_screw, screw_length);
                translate([ 0, 0, -40 ]) explode(-100) threaded_insert(M6x15);
            }
        }
    }
    translate([ -200, 0, 0 ]) rotate([ 0, -90, 180 ]) explode(-50)
    {
        render_2D_sheet((Chipboard40)) frame_left_side_dxf();
        frame_side_screw_positions()
        {
            translate([ 0, 0, -20 ])
            {
                rotate([ 0, 180, 0 ])
                {
                    screw_and_washer(M6_cap_screw, screw_length);
                    translate([ 0, 0, -40 ]) threaded_insert(M6x15);
                }
            }
        }
    }

    translate([ 0, 160, 100 ]) rotate([ 90, 0, 0 ]) render_2D_sheet((Chipboard40)) frame_back_side_dxf();
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
        translate([ 100, -110, 0 ]) circle(20);
    }
}

module frame_back_side_dxf() dxf("frame_back_side")
{
    difference()
    {
        sheet_2D(Chipboard40, 360, 200);
    }
}

module frame_bottom_side_dxf() dxf("frame_bottom_side")
{
    difference()
    {
        sheet_2D(Chipboard40, 360, 580);
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
    explode(50) translate([ 0, 0, -126 ]) yaxis_assembly();
}

if ($preview)
    main_assembly();
// yaxis_assembly();
// yplate_dxf();
