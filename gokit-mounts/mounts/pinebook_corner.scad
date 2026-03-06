// ============================================================
// Pinebook Pro Rear Corner Mount
// ============================================================
// 4-sided shallow box to catch laptop corner
// Slot mount tab attached to OUTSIDE of one wall
// Top retention tabs prevent laptop from lifting out
// Used in pairs at rear left and rear right corners

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_corner_mount() {
    // Box dimensions - minimal size to catch corner
    wall_thickness = corner_wall_thickness;  // 4mm walls
    floor_thickness = 7;  // mm, thick floor
    corner_size = 30;  // mm, internal size of box
    wall_height = pbp_h + pbp_clearance;  // Just tall enough for laptop thickness

    // Total outer dimensions
    outer_size = corner_size + 2 * wall_thickness;

    union() {
        // 4-sided box (floor + 4 walls forming closed perimeter)
        difference() {
            // Outer solid box
            cube([outer_size, outer_size, floor_thickness + wall_height]);

            // Hollow out the inside (above the floor)
            translate([wall_thickness, wall_thickness, floor_thickness])
                cube([corner_size, corner_size, wall_height + 1]);
        }

        // Top retention tabs (extend inward over laptop top surface)
        retention_height = floor_thickness + wall_height;

        // Tab on wall 1 (front wall, along X axis)
        translate([wall_thickness, 0, retention_height])
            cube([corner_arm_length, wall_thickness, corner_arm_thickness]);

        // Tab on wall 2 (left wall, along Y axis)
        translate([0, wall_thickness, retention_height])
            cube([wall_thickness, corner_arm_length, corner_arm_thickness]);

        // Slot mount base attached to OUTSIDE of wall 2 (left wall)
        // Position it centered on the wall exterior face
        translate([-mount_body_d, (outer_size - base_width) / 2, retention_height / 2 - mount_body_h / 2])
            rotate([0, 90, 0])
                rotate([0, 0, -90])
                    slot_mount_base();
    }
}

// Helper to access base_width in this scope
base_width = 28;  // mm, matches slot_mount_base

// Render single mount for preview
pinebook_corner_mount();

// Uncomment to render mirrored pair for printing
// pinebook_corner_mount();
// translate([60, 0, 0])
//     mirror([1, 0, 0])
//         pinebook_corner_mount();
