// ============================================================
// Pinebook Pro Rear Corner Mount
// ============================================================
// Two vertical walls at 90° forming inside corner
// Top retention arm extends over laptop to prevent lift/pivot
// Used in pairs at rear left and rear right corners

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_corner_mount() {
    // Use slot mount base
    base_width = 28;  // mm, matches slot_mount_base
    base_depth = mount_body_d;
    base_height = mount_body_h;

    // Corner wall dimensions
    wall_height = corner_wall_h;
    wall_thickness = corner_wall_thickness;

    // Dimensions for laptop fit (inside corner dimensions)
    inside_width = pbp_w / 2 + pbp_clearance;  // Half the laptop width + clearance
    inside_depth = pbp_d + pbp_clearance;      // Full laptop depth + clearance

    union() {
        // Horizontal base with slot tab and nut pocket
        slot_mount_base();

        // Left wall (perpendicular to base, extends in +Y direction)
        translate([0, base_depth, base_height])
            cube([wall_thickness, inside_depth, wall_height]);

        // Back wall (perpendicular to base, extends in +X direction)
        translate([0, base_depth + inside_depth - wall_thickness, base_height])
            cube([inside_width, wall_thickness, wall_height]);

        // Top retention arm over left wall (extends inward over laptop)
        translate([
            0,
            base_depth,
            base_height + wall_height - corner_arm_thickness
        ])
            cube([corner_arm_length, wall_thickness, corner_arm_thickness]);

        // Top retention arm over back wall (extends inward over laptop)
        translate([
            0,
            base_depth + inside_depth - wall_thickness,
            base_height + wall_height - corner_arm_thickness
        ])
            cube([wall_thickness, corner_arm_length, corner_arm_thickness]);

        // Corner gusset at 90° junction of walls
        translate([wall_thickness, base_depth + inside_depth - wall_thickness, base_height])
            rotate([0, 0, 90])
                linear_extrude(height = wall_height - corner_arm_thickness)
                    polygon([
                        [0, 0],
                        [8, 0],
                        [0, 8]
                    ]);
    }
}

// Render single mount for preview
pinebook_corner_mount();

// Uncomment to render mirrored pair for printing
// pinebook_corner_mount();
// translate([60, 0, 0])
//     mirror([1, 0, 0])
//         pinebook_corner_mount();
