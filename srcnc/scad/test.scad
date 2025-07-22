include <NopSCADlib/core.scad>
include <NopSCADlib/vitamins/linear_bearings.scad>
use <NopSCADlib/utils/layout.scad>

include <ball_screw_supports.scad>

module floating_ball_screw_supports() layout([for (bf = bfs) 80])
{
    floating_ball_screw_support_assembly(bfs[$i]);
}
module fixed_ball_screw_supports() layout([for (bk = bks) 80])
{
    fixed_ball_screw_support_assembly(bks[$i]);
}

if ($preview)
{
    floating_ball_screw_supports();
    translate([ 0, 80, 0 ]) fixed_ball_screw_supports();
}
