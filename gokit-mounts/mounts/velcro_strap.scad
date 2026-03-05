// ============================================================
// Velcro Strap Mount
// ============================================================
// L-shaped mount with horizontal base (slot mount) and vertical arm
// Velcro passes through hole in vertical arm

include <../params.scad>
use <../lib/slot_mount.scad>

module velcro_mount() {
    // Calculate dimensions
    base_width = slot_tab_width + 2 * 4;  // Match slot_mount_base
    base_depth = mount_body_d;
    base_height = mount_body_h;

    // Vertical arm dimensions
    arm_height = 20;  // mm, tall enough to support strapped equipment
    arm_thickness = 4;  // mm, thickness of vertical wall

    // Velcro channel dimensions
    channel_width = velcro_width + velcro_channel_clearance;
    channel_height = 12;  // mm, tall enough for velcro with some clearance

    union() {
        // Horizontal base with slot tab and nut pocket
        slot_mount_base();

        // Vertical arm at back edge
        difference() {
            // Solid vertical wall
            translate([0, base_depth - arm_thickness, base_height])
                cube([base_width, arm_thickness, arm_height]);

            // Velcro channel (horizontal slot through vertical arm)
            translate([
                (base_width - channel_width) / 2,
                base_depth - arm_thickness - 1,
                base_height + (arm_height - channel_height) / 2
            ])
                cube([channel_width, arm_thickness + 2, channel_height]);

            // Add radius to channel edges to prevent velcro abrasion
            // Top edge radius
            translate([
                (base_width - channel_width) / 2,
                base_depth - arm_thickness / 2,
                base_height + (arm_height - channel_height) / 2
            ])
                rotate([0, 90, 0])
                    cylinder(h = channel_width, r = 1, $fn = 16);

            // Bottom edge radius
            translate([
                (base_width - channel_width) / 2,
                base_depth - arm_thickness / 2,
                base_height + (arm_height + channel_height) / 2
            ])
                rotate([0, 90, 0])
                    cylinder(h = channel_width, r = 1, $fn = 16);
        }
    }
}

// Render single mount for preview
velcro_mount();

// Uncomment to render mirrored pair for printing
// velcro_mount();
// translate([40, 0, 0])
//     mirror([1, 0, 0])
//         velcro_mount();
