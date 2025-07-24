include <NopSCADlib/utils/core/core.scad>
use <NopSCADlib/vitamins/ball_bearing.scad>
use <NopSCADlib/vitamins/extrusion.scad>
use <NopSCADlib/vitamins/rail.scad>
use <NopSCADlib/vitamins/screw.scad>
use <NopSCADlib/vitamins/rod.scad>

function lgt_extrusion(type) = type[4];  //! Base plate extrusion type
function lgt_carriage(type) = type[5];   //! Linear guide carriage type
function lgt_ball_screw(type) = type[6]; //! Linear guide carriage type
function lgt_table_top(type) = type[3];  //! Linear guide carriage type
function lgt_plate_thickness(type) = 10; //
function lgt_extrusion_length(type) = type[1] + 90;

linear_guide_table_color = "black";

module linear_guide_table_assembly(type)
{ //! Draw the specified linear_guide_table
    vitamin(str("linear_guide_table(", type[0], "): ", type[0], " linear guide table"));

    rt = lgt_carriage(type);
    et = lgt_extrusion(type);

    extrusion_height = extrusion_width(et);
    rail_length = lgt_extrusion_length(type) - 50;
    translate([ 0, 0, extrusion_height / 2 ])
    {
        rotate([ 90, 90, 90 ]) extrusion(lgt_extrusion(type), lgt_extrusion_length(type));
    }
    for (y = [ 20, -20 ])
    {
        translate([ -25, y, 20 ]) rail_assembly(rt, rail_length, 25);
    }
    linear_guide_table(type);
    linear_guide_table_floating_block(type);
    linear_guide_table_motor_block(type);
}

module linear_guide_table(type)
{
    et = lgt_extrusion(type);
    rt = lgt_carriage(type);
    carriage_height = extrusion_width(et) + carriage_height(rt);
    table_width = type[2];
    table_length = extrusion_height(et);
    table_height = lgt_table_top(type) - carriage_height;

    color(linear_guide_table_color)
    {
        translate([ 0, 0, table_height / 2 + carriage_height ])
            cube([ table_width, table_length, table_height ], center = true);
    }
}

module linear_guide_table_floating_block(type)
{
    et = lgt_extrusion(type);
    block_length = extrusion_height(et);
    block_height = lgt_table_top(type) - 1;

    color(linear_guide_table_color)
    {
        translate([ -lgt_extrusion_length(type) / 2, 0, block_height / 2 ])
            cube([ lgt_plate_thickness(type), block_length, block_height ], center = true);
    }
}

module linear_guide_table_motor_block(type)
{
    et = lgt_extrusion(type);
    block_length = extrusion_height(et);
    block_height = 72; // same for all

    color(linear_guide_table_color)
    {
        translate([ lgt_extrusion_length(type) / 2, 0, block_height / 2 ])
            cube([ lgt_plate_thickness(type), block_length, block_height ], center = true);
    }
}
