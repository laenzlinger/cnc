/*
 * fixture-plate.scad — CNC fixture plate for Hammond 1590DD top panel milling
 *
 * Screws down to SRcnc wasteboard via M5 carriage holes.
 * Case mounted open-side-down: screws go through plate up into case corner bosses.
 * M4 washer between screw head and board prevents pull-through.
 *
 * Coordinate system: center of plate = center of case = machine X110 Y190
 *
 * Wasteboard carriage hole pattern (measured on machine):
 *   SBR12UU carriages, J=28mm K=26mm hole spacing
 *   Outer rectangle: 146×176mm (±73mm X, ±88mm Y)
 *   Inner rectangle: 96×120mm (±48mm X, ±60mm Y)
 *   Carriage centers: ~±60mm X, ~±74mm Y
 *   Using outer 4 holes to avoid case screw interference
 *   Screw: M5, head sits on top of plate
 *
 * 1590DD case screw hole pattern (from datasheet, 178×114mm):
 *   4 corners: ±89mm X, ±57mm Y
 *   2 center (long sides): 0mm X, ±57mm Y
 *   Screw: #6-32 × 12mm countersunk + M4 washer (ø9mm OD)
 *
 * Material: 12.7mm HPL/Trespa board
 * Mill this plate on the SRcnc before using it as a fixture.
 */

// === PARAMETERS ===

plate_thickness = 12.7;     // mm — HPL/Trespa board thickness

// Wasteboard carriage holes — inner X, outer Y of SBR12UU carriages
// Measured on machine: inner X = ±48mm, outer Y = ±88mm
// Clear of case screw pattern (±89mm X × ±57mm Y)
carriage_hole_x = 48;       // ±mm from center (inner X)
carriage_hole_y = 88;       // ±mm from center (outer Y)
carriage_screw_d = 6.0;     // M5 clearance, oversized for position tolerance

// Case screw holes — counterbored for M4 washer + #6-32 shank
// Measured on case: screw pattern 180×111mm
// #6-32 × 12mm countersunk screws + M4 washer (ø9mm OD)
case_hole_x = 90;           // ±mm from center (180/2)
case_hole_y = 55.5;         // ±mm from center (111/2)
case_screw_d   = 4.5;       // #6-32 shank clearance (helical with 4mm tool)
case_cbore_d   = 10.0;      // counterbore for M4 washer (ø9mm + 0.5mm clearance)
case_cbore_depth = 7.7;     // counterbore depth — leaves 5mm below for thread engagement
                            // screw length 12mm → 12 - 5 = 7mm into case boss

// Plate size — covers case holes (±89mm X, ±57mm Y) and carriage holes (±73mm X, ±88mm Y)
plate_w = 220;              // mm — matches machine X travel
plate_h = 200;              // mm — covers carriage holes at ±88mm Y

// === MODULES ===

module carriage_holes() {
    for (x = [-carriage_hole_x, carriage_hole_x])
        for (y = [-carriage_hole_y, carriage_hole_y])
            translate([x, y, 0]) children();
}

module case_holes() {
    // 4 corner screws
    for (x = [-case_hole_x, case_hole_x])
        for (y = [-case_hole_y, case_hole_y])
            translate([x, y, 0]) children();
    // 2 center screws on long sides (X=0, Y=±57)
    for (y = [-case_hole_y, case_hole_y])
        translate([0, y, 0]) children();
}

module fixture_plate() {
    difference() {
        // Plate body
        cube([plate_w, plate_h, plate_thickness], center=true);

        // Case screw holes — counterbore for washer+head, through hole for shank
        case_holes() {
            // Counterbore from top (washer + head recess)
            translate([0, 0, plate_thickness/2 - case_cbore_depth])
                cylinder(d=case_cbore_d, h=case_cbore_depth + 0.01, $fn=32);
            // Shank through hole
            translate([0, 0, -plate_thickness/2 - 0.01])
                cylinder(d=case_screw_d, h=plate_thickness + 0.02, $fn=32);
        }

        // Carriage holes — M5 through hole
        carriage_holes()
            translate([0, 0, -plate_thickness/2 - 0.01])
                cylinder(d=carriage_screw_d, h=plate_thickness + 0.02, $fn=32);
    }
}

// === RENDER ===

fixture_plate();
