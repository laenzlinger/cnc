include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/linear_bearings.scad>
include <NopSCADlib/vitamins/screws.scad>
use <NopSCADlib/vitamins/leadnut.scad>
use <NopSCADlib/vitamins/rod.scad>
use <NopSCADlib/vitamins/screw.scad>

srcnc();

module srcnc()
{
    yaxis();
    //    frame();
}

module yaxis()
{

    $show_threads = true; // Show threads on leadscrews
    SFU1204 = [
        "SFU1204", "Leadscrew nut for SFU1204", 12, 22, 35, 42, 8, 0, 6, 4.5, 32 / 2, M4_cap_screw, 4, 10, 30, "#DFDAC5"
    ];

    LNH = [ "LNH", "Lead Screw Nut Housing", 30, 50, 36, -1, 24, 35, M5_cs_cap_screw, 15, SFU1204, 15 ];
    leadnuthousing(LNH);
    translate_z(leadnuthousing_height(LNH) / 2)
    {
        leadnut(leadnuthousing_nut(LNH));
        leadnuthousing_nut_screw_positions(LNH)
            screw(leadnut_screw(leadnuthousing_nut(LNH)), leadnuthousing_nut_screw_length(LNH));
    }
    leadscrew(12, 550, 4, 1);
}
