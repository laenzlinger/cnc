$pp1_colour = "grey"; // Override any global defaults here if required, see NopSCADlib/global_defs.scad.
$show_threads = true; // Show threads on leadscrews

//! Small rigid CNC.

include <NopSCADlib/lib.scad> // Includes all the vitamins and utilities in NopSCADlib but not the printed parts.
include <NopSCADlib/vitamins/sbr_rails.scad>
use <NopSCADlib/vitamins/sbr_rail.scad>

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

module yaxis_assembly() assembly("yaxis")
{
    rotate([ 90, -90, 0 ])
    {
        leadscrew(12, 550, 4, 1);
        leadnuthousing(LNH);
        nut = leadnuthousing_nut(LNH);
        translate_z(leadnuthousing_height(LNH) / 2)
        {
            leadnut(nut);
            leadnuthousing_nut_screw_positions(LNH) screw(leadnut_screw(nut), leadnuthousing_nut_screw_length(LNH));
        }
    }
    translate([ 80, 0, 0 ]) yrail();
    translate([ -80, 0, 0 ]) yrail();
}

module yrail()
{
    rotate([ 90, 180, 0 ])
    {
        length = 550;
        sheet = 8;
        rail = SBR12S;
        carriage = sbr_rail_carriage(rail);
        sbr_rail(rail, length);
        screw = sbr_rail_screw(rail);
        translate([ 00, 0, 60 ]) sbr_bearing_block_assembly(carriage, sheet);
        translate([ 00, 0, -60 ]) sbr_bearing_block_assembly(carriage, sheet);
        sbr_screw_positions(rail, length) explode(20) rotate([ 90, 0, 0 ]) screw(screw, 18);
    }
}

//! Assembly instructions in Markdown format in front of each module that makes an assembly.
module main_assembly() assembly("main")
{
    yaxis_assembly();
    //    ...
}

if ($preview)
    main_assembly();
