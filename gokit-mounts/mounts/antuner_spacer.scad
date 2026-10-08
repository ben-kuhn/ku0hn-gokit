// ============================================================
// AnTuner AT-100M Pro — Hanging Spacer
// ============================================================
// Replaces the SWR meter that used to fill the 1U front gap on the
// inverted upper shelf. The AT-100M Pro is short, so mounted in the
// gap its screen/power/tune buttons sit behind the shelf front lip
// (shelf_lip_h). This spacer bolts to the shelf slots from BELOW and
// drops the tuner below the lip; the front panel faces the user,
// level, clearing the lip by (antuner_drop + antuner_ctrl_top -
// shelf_lip_h).
//
// Lean frame layout:
//   - top frame: two side walls + a central tab bar + front/back rails
//     (open windows between them) with the slot tabs above the tuner
//   - register ledges on the walls set the tuner top at antuner_drop
//   - full velcro loop: under the tuner -> out through a lower wall slot
//     -> up OUTSIDE the wall -> back in through an upper wall window
//     -> across the top (above the tuner) -> out the other side and round.
//     The strap never touches the tuner top.
//
// Slot mounts sit directly above the tuner (antuner_tab_x); shelf slots
// are long rails so only the tab X spacing must match the rail pitch.
//
// Hardware: 2x M5x10-12 screws + 10mm washers from above, 2x M5 hex
// nuts pressed up into the pockets from below (1mm skin left on top).
//
// Print plate-down (walls up): print_orientation = true;
// ============================================================

include <../params.scad>

show_tuner = true;          // ghost tuner for fit checking (preview only)
print_orientation = false;  // true = frame down / walls up for printing

// ---------------- derived geometry ----------------
arm_inner  = antuner_w / 2 + antuner_fit;   // wall inner face
arm_outer  = arm_inner + antuner_wall;      // wall outer face
cradle     = antuner_cradle_len;
y_back     = -cradle / 2;
tuner_bot  = -(antuner_drop + antuner_h);
wall_bot   = tuner_bot - antuner_foot;

nut_d      = (m5_nut_w + nut_pocket_tol) / cos(30);  // hex pocket across-corners

module antuner_spacer() {
    difference() {
        union() {
            // Side walls
            for (sx = [-1, 1])
                translate([sx > 0 ? arm_inner : -arm_outer, y_back, wall_bot])
                    cube([antuner_wall, cradle, -wall_bot]);

            // Central tab bar (holds the two slot tabs above the tuner)
            translate([-arm_outer, -antuner_bar_h, -antuner_plate_t])
                cube([2 * arm_outer, 2 * antuner_bar_h, antuner_plate_t]);

            // Front / back frame rails (brace the walls)
            for (sy = [-1, 1])
                translate([-arm_outer, sy * cradle / 2 - (sy > 0 ? antuner_rail_w : 0), -antuner_plate_t])
                    cube([2 * arm_outer, antuner_rail_w, antuner_plate_t]);

            // Register ledges — tuner top rests against these at z = -antuner_drop
            for (sx = [-1, 1])
                translate([sx > 0 ? arm_inner - antuner_ledge : -arm_inner, y_back, -antuner_drop])
                    cube([antuner_ledge, cradle, antuner_ledge_t]);

            // Slot tabs, directly above the tuner
            for (sx = [-1, 1])
                translate([sx * antuner_tab_x - slot_tab_width / 2, -slot_tab_width / 2, 0])
                    cube([slot_tab_width, slot_tab_width, antuner_tab_h]);
        }

        // Lower strap slots — open at the bottom edge (no wasted material below)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([
                sx > 0 ? arm_inner - 1 : -arm_outer - 1,
                sy * antuner_strap_y - antuner_channel_w / 2,
                wall_bot - 1
            ])
                cube([antuner_wall + 2, antuner_channel_w, (tuner_bot + 2) - wall_bot + 1]);

        // Upper strap windows through the walls (above the tuner)
        for (sx = [-1, 1], sy = [-1, 1])
            translate([
                sx > 0 ? arm_inner - 1 : -arm_outer - 1,
                sy * antuner_strap_y - antuner_channel_w / 2,
                -antuner_plate_t - antuner_window_h
            ])
                cube([antuner_wall + 2, antuner_channel_w, antuner_window_h]);

        // Slot-tab hardware — M5 from above, nut pressed up from below
        for (sx = [-1, 1]) {
            tx = sx * antuner_tab_x;
            translate([tx, 0, -antuner_plate_t - 1])
                cylinder(h = antuner_plate_t + antuner_tab_h + 2, d = m5_screw_d, $fn = 32);
            translate([tx, 0, -antuner_plate_t])
                cylinder(h = m5_nut_h, d = nut_d, $fn = 6);
        }
    }
}

// Transparent ghost of the tuner, for fit checking in preview only
module antuner_reference() {
    % translate([-antuner_w / 2, -antuner_d / 2, tuner_bot])
        cube([antuner_w, antuner_d, antuner_h]);
}

if (print_orientation)
    rotate([180, 0, 0]) antuner_spacer();
else
    antuner_spacer();

if (show_tuner)
    antuner_reference();
