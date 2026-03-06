// ============================================================
// Pinebook Pro Rear Corner Mount
// ============================================================
// 4-sided box: floor, ceiling, and 2 perpendicular walls
// Slot mount tab attached to OUTSIDE of one wall
// Used in pairs at rear left and rear right corners

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_corner_mount() {
    // Box dimensions - minimal size to catch corner
    wall_thickness = corner_wall_thickness;  // 4mm walls
    floor_thickness = 7;  // mm, thick floor
    ceiling_thickness = corner_arm_thickness;  // 4mm ceiling
    corner_size = 30;  // mm, internal size of box
    internal_height = pbp_h + pbp_clearance;  // Just tall enough for laptop thickness

    total_height = floor_thickness + internal_height + ceiling_thickness;

    union() {
        // Floor
        cube([corner_size, corner_size, floor_thickness]);

        // Wall 1 (along X axis)
        cube([corner_size, wall_thickness, total_height]);

        // Wall 2 (along Y axis)
        cube([wall_thickness, corner_size, total_height]);

        // Ceiling (top surface)
        translate([0, 0, floor_thickness + internal_height])
            cube([corner_size, corner_size, ceiling_thickness]);

        // Slot mount base extends out from floor as a continuation
        // Positioned to the left of wall 2 (in -X direction)
        translate([-base_width, 0, 0])
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
