// ============================================================
// Velcro Strap Mount
// ============================================================
// L-shaped mount with horizontal base (slot mount) and vertical arm
// Velcro passes through hole in vertical arm

include <../params.scad>
use <../lib/slot_mount.scad>

module velcro_mount() {
    // Calculate dimensions - must match slot_mount_base
    base_width = 28;  // mm, matches slot_mount_base
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

        // Diagonal support gussets on each side (on back of vertical arm)
        // These fill the 90-degree corner between horizontal base and back of vertical wall
        gusset_depth = 12;  // mm, how far gusset extends back on base (in Y direction)
        gusset_height = 15;  // mm, height of triangular support up vertical arm (in Z direction)
        gusset_thickness = 5;  // mm, thickness of gusset (in X direction)

        // Left gusset - right triangle in the YZ plane, extruded in X direction
        // Position: left side of mount (X=0), back corner where wall meets base
        translate([0, base_depth, base_height])
            rotate([90, 0, 90])
                linear_extrude(height = gusset_thickness)
                    polygon([
                        [0, 0],                    // At back of wall, base of wall (origin)
                        [-gusset_depth, 0],        // Back along base
                        [0, gusset_height]         // Up the wall
                    ]);

        // Right gusset - mirror on the right side
        translate([base_width - gusset_thickness, base_depth, base_height])
            rotate([90, 0, 90])
                linear_extrude(height = gusset_thickness)
                    polygon([
                        [0, 0],                    // At back of wall, base of wall (origin)
                        [-gusset_depth, 0],        // Back along base
                        [0, gusset_height]         // Up the wall
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
