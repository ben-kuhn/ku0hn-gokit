// ============================================================
// Velcro Strap Mount
// ============================================================
// L-shaped mount with horizontal base (slot mount) and vertical arm
// Velcro passes through hole in vertical arm

include <../params.scad>
use <../lib/slot_mount.scad>

module velcro_mount() {
    // Calculate dimensions - must match slot_mount_base
    base_width = 22;  // mm, matches slot_mount_base
    base_depth = mount_body_d;
    base_height = mount_body_h;

    // Vertical arm dimensions
    arm_height = 20;  // mm, tall enough to support strapped equipment
    arm_thickness = 4;  // mm, thickness of vertical wall

    // Velcro channel dimensions
    channel_width = velcro_width + velcro_channel_clearance;
    channel_height = 6;  // mm, reduced for strength - just enough for velcro
    channel_radius = 1.5;  // mm, radius for smoothed corners

    union() {
        // Horizontal base with slot tab and nut pocket
        slot_mount_base();

        // Vertical arm at back edge
        difference() {
            // Solid vertical wall
            translate([0, base_depth - arm_thickness, base_height])
                cube([base_width, arm_thickness, arm_height]);

            // Velcro channel (horizontal slot through vertical arm)
            // Positioned closer to top for better lower wall strength
            translate([
                (base_width - channel_width) / 2,
                base_depth - arm_thickness - 1,
                base_height + arm_height - channel_height - 3  // 3mm from top
            ])
                cube([channel_width, arm_thickness + 2, channel_height]);

            // Add rounded corners on front and back edges of channel opening
            // These are subtractive cylinders positioned at the corners
            // Front left corner
            translate([
                (base_width - channel_width) / 2 + channel_radius,
                base_depth - arm_thickness,
                base_height + arm_height - channel_height - 3 + channel_radius
            ])
                rotate([90, 0, 0])
                    cylinder(h = arm_thickness, r = channel_radius, center = true, $fn = 16);

            // Front right corner
            translate([
                (base_width + channel_width) / 2 - channel_radius,
                base_depth - arm_thickness,
                base_height + arm_height - channel_height - 3 + channel_radius
            ])
                rotate([90, 0, 0])
                    cylinder(h = arm_thickness, r = channel_radius, center = true, $fn = 16);

            // Front left bottom corner
            translate([
                (base_width - channel_width) / 2 + channel_radius,
                base_depth - arm_thickness,
                base_height + arm_height - 3 - channel_radius
            ])
                rotate([90, 0, 0])
                    cylinder(h = arm_thickness, r = channel_radius, center = true, $fn = 16);

            // Front right bottom corner
            translate([
                (base_width + channel_width) / 2 - channel_radius,
                base_depth - arm_thickness,
                base_height + arm_height - 3 - channel_radius
            ])
                rotate([90, 0, 0])
                    cylinder(h = arm_thickness, r = channel_radius, center = true, $fn = 16);
        }

        // Diagonal support gussets on each side
        gusset_height = 10;  // mm, height of triangular support
        gusset_thickness = 3;  // mm, thickness of gusset

        // Left gusset
        translate([0, base_depth - arm_thickness, base_height])
            linear_extrude(height = gusset_thickness)
                polygon([
                    [0, 0],
                    [gusset_height, 0],
                    [0, gusset_height]
                ]);

        // Right gusset
        translate([base_width - gusset_thickness, base_depth - arm_thickness, base_height])
            linear_extrude(height = gusset_thickness)
                polygon([
                    [0, 0],
                    [gusset_thickness, 0],
                    [gusset_thickness, gusset_height],
                    [0, gusset_height]
                ]);
    }
}

// Render single mount for preview
velcro_mount();

// Uncomment to render mirrored pair for printing
// velcro_mount();
// translate([40, 0, 0])
//     mirror([1, 0, 0])
//         velcro_mount();
