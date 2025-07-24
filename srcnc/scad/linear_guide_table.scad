include <NopSCADlib/utils/core/core.scad>
include <NopSCADlib/vitamins/stepper_motors.scad>
use <NopSCADlib/vitamins/ball_bearing.scad>
use <NopSCADlib/vitamins/extrusion.scad>
use <NopSCADlib/vitamins/rail.scad>
use <NopSCADlib/vitamins/rod.scad>
use <NopSCADlib/vitamins/screw.scad>
use <NopSCADlib/vitamins/stepper_motor.scad>

function lgt_table_top(type) = type[3];        //! Hieght of the table top
function lgt_ballscrew_height(type) = type[4]; //! Height of the ballscrew center
function lgt_extrusion(type) = type[5];        //! Base plate extrusion type
function lgt_carriage(type) = type[6];         //! Linear guide carriage type

function lgt_plate_thickness(type) = 10;
function lgt_extrusion_length(type) = type[1] + 90;

linear_guide_table_color = "black";

module linear_guide_table_assembly(type)
{ //! Draw the specified linear_guide_table
    vitamin(str("linear_guide_table(", type[0], "): ", type[0], " linear guide table"));

    rt = lgt_carriage(type);
    et = lgt_extrusion(type);

    not_on_bom() no_explode()
    {
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
        translate([ -15, 0, lgt_ballscrew_height(type) ])
        {
            rotate([ 0, 90, 0 ]) leadscrew(12, rail_length + 30, 4, 1);
        }
    }
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
    block_height = 73; // same for all

    color(linear_guide_table_color)
    {
        translate([ lgt_extrusion_length(type) / 2, 0, 0 ])

            difference()
        {
            translate([ 0, 0, block_height / 2 ])
                cube([ lgt_plate_thickness(type), block_length, block_height ], center = true);
            translate([ 0, 0, lgt_ballscrew_height(type) ]) rotate([ 0, 90, 0 ])
            {
                NEMA_screw_positions(NEMA23_51) cylinder(h = 30, d = 4.2, center = true);
                NEMA_screw_positions(NEMA17_40) cylinder(h = 30, d = 4.0, center = true);
                cylinder(h = 30, d = 20, center = true); // for NEMA17_47
            }
        }
    }
}
