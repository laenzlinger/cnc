//
// BF ball screw supports
//
// https: // www.aliexpress.com/item/1005005320373835.html
// include <NopSCADlib/lib.scad> // Includes all the vitamins and utilities in NopSCADlib but not the printed parts.
include <NopSCADlib/vitamins/extrusions.scad>
// include <NopSCADlib/vitamins/screws.scad>
include <NopSCADlib/vitamins/rails.scad>

SGX_5080 = [ "SGX_5080", 100, 50, 59, 45, E2080, MGN12H_carriage ];

use <linear_guide_table.scad>

// linear_guide_table_assembly(SGX_5080);
