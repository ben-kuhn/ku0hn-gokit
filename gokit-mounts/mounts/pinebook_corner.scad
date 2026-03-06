// ============================================================
// Pinebook Pro Rear Corner Mount
// ============================================================
// 3-sided hollow cube (box with one side open)
// Slot mount tab attached to one of the sides
// Used in pairs at rear left and rear right corners

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_corner_mount() {
    // Corner box dimensions
    wall_thickness = corner_wall_thickness;  // 4mm walls
    box_height = corner_wall_h;  // 20mm tall

    // Inside dimensions (laptop fit with clearance)
    inside_width = pbp_w / 2 + pbp_clearance;  // Half laptop width + clearance
    inside_depth = pbp_d + pbp_clearance;      // Full laptop depth + clearance
    inside_height = pbp_h + pbp_clearance;     // Laptop thickness + clearance

    // Outside dimensions
    outside_width = inside_width + wall_thickness;
    outside_depth = inside_depth + wall_thickness;

    difference() {
        union() {
            // 3-sided hollow cube (bottom + 2 perpendicular sides)
            // Bottom
            cube([outside_width, outside_depth, wall_thickness]);

            // Side wall 1 (along X axis)
            cube([outside_width, wall_thickness, box_height]);

            // Side wall 2 (along Y axis)
            cube([wall_thickness, outside_depth, box_height]);

            // Top retention lip (extends inward over laptop)
            // Along side wall 1
            translate([0, 0, inside_height + wall_thickness])
                cube([corner_arm_length, wall_thickness, corner_arm_thickness]);

            // Along side wall 2
            translate([0, 0, inside_height + wall_thickness])
                cube([wall_thickness, corner_arm_length, corner_arm_thickness]);
        }

        // Hollow out the inside
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([inside_width, inside_depth, box_height]);
    }

    // Slot mount base attached to side wall 2 (the one along Y axis)
    translate([0, (outside_depth - mount_body_d) / 2, -mount_body_h])
        rotate([0, 0, 0])
            slot_mount_base();
}

// Render single mount for preview
pinebook_corner_mount();

// Uncomment to render mirrored pair for printing
// pinebook_corner_mount();
// translate([60, 0, 0])
//     mirror([1, 0, 0])
//         pinebook_corner_mount();
