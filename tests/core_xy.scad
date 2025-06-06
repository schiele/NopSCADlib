//
// NopSCADlib Copyright Chris Palmer 2020
// nop.head@gmail.com
// hydraraptor.blogspot.com
//
// This file is part of NopSCADlib.
//
// NopSCADlib is free software: you can redistribute it and/or modify it under the terms of the
// GNU General Public License as published by the Free Software Foundation, either version 3 of
// the License, or (at your option) any later version.
//
// NopSCADlib is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
// without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with NopSCADlib.
// If not, see <https://www.gnu.org/licenses/>.
//

include <../core.scad>
include <../vitamins/pulleys.scad>
include <../vitamins/stepper_motors.scad>
include <../vitamins/washers.scad>

include <../utils/core_xy.scad>


module coreXY_belts_test() {
    coreXY_type = coreXY_GT2_20_16;
    plain_idler = coreXY_plain_idler(coreXY_type);
    toothed_idler = coreXY_toothed_idler(coreXY_type);

    pos = [100, 50];
    coreXYPosBL = [0, 0, 0];
    coreXYPosTR = [200, 150, 0];
    separation = [0, coreXY_coincident_separation(coreXY_type).y, pulley_height(plain_idler) + washer_thickness(M3_washer)];
    x_gap = 10;

    plain_idler_offset = [10, 5];
    upper_drive_pulley_offset = [40, 0];
    lower_drive_pulley_offset = [0, 0];

    coreXY_belts(coreXY_type,
        pos,
        coreXYPosBL,
        coreXYPosTR,
        separation,
        x_gap,
        plain_idler_offset,
        upper_drive_pulley_offset,
        lower_drive_pulley_offset,
        show_pulleys = true);


    translate([coreXYPosBL.x + separation.x/2, coreXYPosTR.y + upper_drive_pulley_offset.y, separation.z/2]) {
        // add the upper drive pulley stepper motor
        translate([coreXY_drive_pulley_x_alignment(coreXY_type) + upper_drive_pulley_offset.x, 0, -pulley_height(coreXY_drive_pulley(coreXY_type))])
            NEMA(NEMA17_40);

        // add the screws for the upper drive offset idler pulleys if required
        if (upper_drive_pulley_offset.x > 0) {
            translate(coreXY_drive_plain_idler_offset(coreXY_type) + plain_idler_offset)
                translate([0, -upper_drive_pulley_offset.y, -pulley_offset(plain_idler)])
                    screw(M3_cap_screw, 20);
            translate(coreXY_drive_toothed_idler_offset(coreXY_type))
                translate([0, -upper_drive_pulley_offset.y, -pulley_offset(toothed_idler)])
                    screw(M3_cap_screw, 20);
         } else if (upper_drive_pulley_offset.x < 0) {
            translate([-pulley_od(plain_idler), coreXY_drive_plain_idler_offset(coreXY_type).y + plain_idler_offset.y])
                translate([0, -upper_drive_pulley_offset.y, -pulley_offset(plain_idler)])
                    screw(M3_cap_screw, 20);
            translate([2*coreXY_drive_pulley_x_alignment(coreXY_type) + plain_idler_offset.x, coreXY_drive_toothed_idler_offset(coreXY_type).y])
                translate([0, -upper_drive_pulley_offset.y, -pulley_offset(toothed_idler)])
                    screw(M3_cap_screw, 20);
        }
    }

    translate([coreXYPosTR.x - separation.x/2, coreXYPosTR.y + lower_drive_pulley_offset.y, -separation.z/2]) {
        // add the lower drive pulley stepper motor
        translate([-coreXY_drive_pulley_x_alignment(coreXY_type) + lower_drive_pulley_offset.x, 0, -pulley_height(coreXY_drive_pulley(coreXY_type))])
            NEMA(NEMA17_40);

        // add the screws for the lower drive offset idler pulleys if required
        if (lower_drive_pulley_offset.x < 0) {
            translate([-coreXY_drive_plain_idler_offset(coreXY_type).x - plain_idler_offset.x, coreXY_drive_plain_idler_offset(coreXY_type).y + plain_idler_offset.y])
                translate([0, -lower_drive_pulley_offset.y, -pulley_offset(plain_idler)])
                    screw(M3_cap_screw, 20);
            translate(coreXY_drive_toothed_idler_offset(coreXY_type))
                translate([0, -lower_drive_pulley_offset.y, -pulley_offset(toothed_idler)])
                    screw(M3_cap_screw, 20);
        } else if (lower_drive_pulley_offset.x > 0) {
            translate([pulley_od(plain_idler), coreXY_drive_plain_idler_offset(coreXY_type).y + plain_idler_offset.y])
                translate([0, -lower_drive_pulley_offset.y, -pulley_offset(plain_idler)])
                    screw(M3_cap_screw, 20);
            translate([-2*coreXY_drive_pulley_x_alignment(coreXY_type) - plain_idler_offset.x, coreXY_drive_toothed_idler_offset(coreXY_type).y])
                translate([0, -lower_drive_pulley_offset.y, -pulley_offset(toothed_idler)])
                    screw(M3_cap_screw, 20);
        }
    }

    // add the screw for the left upper idler pulley
    translate([coreXYPosBL.x + separation.x/2, coreXYPosBL.y, separation.z])
        screw(M3_cap_screw, 20);

    // add the screw for the right upper idler pulley
    translate([coreXYPosTR.x + separation.x/2, coreXYPosBL.y, separation.z])
        screw(M3_cap_screw, 20);

    if (separation.x != 0) {
        // add the screw for the left lower idler pulley
        translate([coreXYPosBL.x - separation.x/2, coreXYPosBL.y, 0])
            screw(M3_cap_screw, 20);

        // add the screw for the right lower idler pulley
        translate([coreXYPosTR.x - separation.x/2, coreXYPosBL.y, 0])
            screw(M3_cap_screw, 20);
    }

    translate([-separation.x/2, pos.y + coreXYPosBL.y -separation.y/2, -separation.z/2 + pulley_height(plain_idler)/2]) {
        // add the screw for the left Y carriage toothed idler
        translate([coreXYPosBL.x, coreXY_toothed_idler_offset(coreXY_type).y, 0])
            screw(M3_cap_screw, 20);
        // add the screw for the left Y carriage plain idler
        translate([coreXYPosBL.x + separation.x + coreXY_plain_idler_offset(coreXY_type).x + (upper_drive_pulley_offset.x == 0 ? 0 : plain_idler_offset.x), separation.y + coreXY_plain_idler_offset(coreXY_type).y, separation.z])
            screw(M3_cap_screw, 20);
        // add the screw for the right Y carriage toothed idler
        translate([coreXYPosTR.x + separation.x, coreXY_toothed_idler_offset(coreXY_type).y, separation.z])
            screw(M3_cap_screw, 20);
        // add the screw for the right Y carriage plain idler
        translate([coreXYPosTR.x - coreXY_plain_idler_offset(coreXY_type).x - (lower_drive_pulley_offset.x == 0 ? 0 : plain_idler_offset.x), separation.y + coreXY_plain_idler_offset(coreXY_type).y, 0])
            screw(M3_cap_screw, 20);
    }
}

module coreXY_motor_in_back_test1() {
    size = [200,200];
    pos = [100,100];
    separation = [20,5,10];


    coreXY(coreXY_GT2_20_16, size, pos, separation, x_gap = 0, plain_idler_offset = [0, 0], upper_drive_pulley_offset = [0, 0], lower_drive_pulley_offset = [0, 0], show_pulleys = true, left_lower = false, motor_back = true);

    rotate([180,0,0])
    translate (
        [ separation.x/2
        , 0
        , -separation.z/2 -15 ])
    NEMA(NEMA17_40);
    translate (
        [ size.x - separation.x/2
        , 0
        , -separation.z/2 - 15 ])
    NEMA(NEMA17_40);
}

module coreXY_motor_in_back_test2() {
    size = [200,200];
    pos = [100,100];
    separation = [0,5,10];
    upper_drive_pulley_offset = [20, 5];
    lower_drive_pulley_offset = [20, 5];


    coreXY(coreXY_GT2_20_16, size, pos, separation, x_gap = 0, plain_idler_offset = [20, 0], upper_drive_pulley_offset = upper_drive_pulley_offset, lower_drive_pulley_offset = lower_drive_pulley_offset, show_pulleys = true, left_lower = false, motor_back = true);

    translate (
        [ size.x - separation.x/2 - lower_drive_pulley_offset.x
        , lower_drive_pulley_offset.y
        , -separation.z/2 - 15 ])
    NEMA(NEMA17_40);

    translate (
        [ separation.x/2 + upper_drive_pulley_offset.x
        , upper_drive_pulley_offset.y
        , separation.z/2 - 25 ])
    NEMA(NEMA17_40);
}


if ($preview) {
    coreXY_belts_test();

    translate ([-250, 0,0])
        coreXY_motor_in_back_test1();

    translate ([-250, -250,0])
        coreXY_motor_in_back_test2();
}
