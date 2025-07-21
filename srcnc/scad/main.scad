$pp1_colour = "grey"; // Override any global defaults here if required, see NopSCADlib/global_defs.scad.
$show_threads = true; // Show threads on leadscrews

//! Small rigid CNC.

include <../../parts/NopSCADlib/lib.scad> // Includes all the vitamins and utilities in NopSCADlib but not the printed parts.

module yaxis_assembly() assembly("yaxix")
{
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

    //    ...
}

//! Assembly instructions in Markdown format in front of each module that makes an assembly.
module main_assembly() assembly("main")
{
    yaxis_assembly();
    //    ...
}

if ($preview)
    main_assembly();
