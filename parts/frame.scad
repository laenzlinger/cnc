include <BOSL2/screws.scad>
include <BOSL2/std.scad>

$fn = 100;
wood = "#ad8a70";

diff("hole") frame();

module frame()
{
    left(200) color_this(wood) cuboid([ 40, 360, 400 ]) attach(LEFT) union()
    {
        left(160) z_screws();
        fwd(180) xy_screws();
    };
    right(200) color_this(wood) cuboid([ 40, 360, 400 ]) attach(RIGHT) union()
    {
        right(160) z_screws();
        fwd(180) xy_screws();
    };
    up(100) back(160) color_this(wood) cuboid([ 360, 40, 200 ]);
    down(184) color_this(wood) cuboid([ 360, 580, 32 ]);
}

module z_screws()
{
    {
        back(30) mounting_screw();
        back(100) mounting_screw();
        back(170) mounting_screw();
    }
}

module xy_screws()
{
    {

        left(160) mounting_screw();
        left(80) mounting_screw();
        mounting_screw();
        right(80) mounting_screw();
        right(160) mounting_screw();
    }
}

module mounting_screw()
{
    screw("M6,55", anchor = "head_bot", head = "socket", drive = "hex");
    tag("hole") screw_hole("M6,40", anchor = "top");
}
