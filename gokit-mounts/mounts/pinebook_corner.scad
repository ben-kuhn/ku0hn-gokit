// ============================================================
// Pinebook Pro Rear Corner Mount
// ============================================================
// Minimal 3-sided corner pocket to catch laptop corner
// Slot mount tab attached to outside of one side wall
// Top retention tabs prevent laptop from lifting out
// Used in pairs at rear left and rear right corners

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_corner_mount() {
    // Corner pocket dimensions - minimal size to catch corner
    wall_thickness = corner_wall_thickness;  // 4mm walls
    corner_size = 30;  // mm, how far each wall extends (minimal to catch corner)
    wall_height = pbp_h + pbp_clearance + wall_thickness + 2;  // Just tall enough for laptop + bottom + retention tab

    // Inside dimensions
    inside_height = pbp_h + pbp_clearance;  // Laptop thickness + clearance

    union() {
        // 3-sided corner pocket
        difference() {
            // Outer solid corner
            union() {
                // Bottom floor
                cube([corner_size, corner_size, wall_thickness]);

                // Side wall 1 (along X axis)
                cube([corner_size, wall_thickness, wall_height]);

                // Side wall 2 (along Y axis)
                cube([wall_thickness, corner_size, wall_height]);
            }

            // Hollow out the inside (above the floor)
            translate([wall_thickness, wall_thickness, wall_thickness])
                cube([corner_size, corner_size, wall_height]);
        }

        // Top retention tabs (extend inward over laptop top surface)
        // Tab on side wall 1
        translate([0, 0, wall_thickness + inside_height])
            cube([corner_arm_length, wall_thickness, corner_arm_thickness]);

        // Tab on side wall 2
        translate([0, 0, wall_thickness + inside_height])
            cube([wall_thickness, corner_arm_length, corner_arm_thickness]);

        // Slot mount base attached to OUTSIDE of side wall 2
        translate([-mount_body_d, (corner_size - base_width) / 2, (wall_height - mount_body_h) / 2])
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
