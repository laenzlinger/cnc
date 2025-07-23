//
// BF ball screw supports
//
// https://cdn.shopify.com/s/files/1/0719/0800/0031/products/Bearing_Block_Dimensions__55388.1504037304.1280.1280_1.jpg?v=1684754246

include <NopSCADlib/vitamins/ball_bearings.scad>
include<NopSCADlib/vitamins/screws.scad>

//              d1   L   B   H   h  B1  H1     E   P  d2   X      Y   Z
BF10 = [ "BF10", 8, 20, 60, 39, 22, 34, 32.5, 15, 46, 5.5, 6.6, 10.8, 5, BB608, M5_cap_screw ];

bfs = [BF10];

//            d1  L  L1  L3 C1  B   H   h   B1  H1    E   P   d2   X    Y    Z
BK10 =
    [ "BK10", 10, 25, 5, 5, 13, 60, 39, 22, 34, 32.5, 15, 46, 5.5, 6.6, 10.8, 5, BB6200, M5_cap_screw, M4_cap_screw ];

bks = [BK10];

use <ball_screw_support.scad>
