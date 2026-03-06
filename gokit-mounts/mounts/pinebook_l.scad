// ============================================================
// Pinebook Pro Front L-Mount
// ============================================================
// L-shaped mount with horizontal arm extending over laptop front edge
// Used in pairs at front left and front right positions

include <../params.scad>
use <../lib/slot_mount.scad>

module pinebook_l_mount() {
    // Use slot mount base
    base_width = 28;  // mm, matches slot_mount_base
    base_depth = mount_body_d;
    base_height = mount_body_h;

    // Vertical riser dimensions
    riser_height = pbp_h + pbp_clearance + l_arm_thickness;  // Tall enough to clear laptop + arm thickness
    riser_width = 20;  // mm, width of vertical section
    riser_thickness = 8;  // mm, front-to-back thickness

    union() {
        // Horizontal base with slot tab and nut pocket
        slot_mount_base();

        // Vertical riser (stands up from base)
        translate([(base_width - riser_width) / 2, 0, base_height])
            cube([riser_width, riser_thickness, riser_height]);

        // Horizontal arm (extends over laptop top)
        // Positioned at top of riser, extends forward
        translate([
            (base_width - riser_width) / 2,
            riser_thickness,
            base_height + riser_height - l_arm_thickness
        ])
            cube([riser_width, l_arm_length, l_arm_thickness]);

        // Add small support gussets at arm corners
        gusset_size = 4;  // mm

        // Left front gusset
        translate([
            (base_width - riser_width) / 2,
            riser_thickness,
            base_height + riser_height - l_arm_thickness
        ])
            rotate([0, -90, 0])
                linear_extrude(height = 2)
                    polygon([
                        [0, 0],
                        [l_arm_thickness, 0],
                        [0, gusset_size]
                    ]);

        // Right front gusset
        translate([
            (base_width + riser_width) / 2 - 2,
            riser_thickness,
            base_height + riser_height - l_arm_thickness
        ])
            rotate([0, -90, 0])
                linear_extrude(height = 2)
                    polygon([
                        [0, 0],
                        [l_arm_thickness, 0],
                        [0, gusset_size]
                    ]);
    }
}

// Render single mount for preview
pinebook_l_mount();

// Uncomment to render pair for printing
// pinebook_l_mount();
// translate([35, 0, 0])
//     pinebook_l_mount();
