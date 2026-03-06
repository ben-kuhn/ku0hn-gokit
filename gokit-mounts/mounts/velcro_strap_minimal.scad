// ============================================================
// Velcro Strap Mount - MINIMAL Version
// ============================================================
// Compact L-shaped mount with minimal base footprint
// Takes up less shelf space while maintaining structural integrity

include <../params.scad>
use <../lib/slot_mount.scad>

module velcro_mount_minimal() {
    // Calculate dimensions
    base_width = 28;  // mm, same as regular - needed for nut pocket and slot tab
    base_depth = 12;  // mm, MINIMAL - just enough for stability
    base_height = mount_body_h;

    // Vertical arm dimensions
    arm_height = 20;  // mm, tall enough to support strapped equipment
    arm_thickness = 4;  // mm, thickness of vertical wall

    // Velcro channel dimensions
    channel_width = velcro_width + velcro_channel_clearance;
    channel_height = 6;  // mm, reduced for strength - just enough for velcro
    channel_top_radius = 2.5;  // mm, radius for rounded top edge

    union() {
        // Minimal horizontal base with slot tab and nut pocket
        // Custom minimal base instead of using slot_mount_base
        difference() {
            union() {
                // Main horizontal base body (minimal depth)
                translate([0, 0, 0])
                    cube([base_width, base_depth, base_height]);

                // Slot tab (extends downward from bottom of base)
                translate([(base_width - slot_tab_width) / 2,
                          (base_depth - slot_tab_width) / 2,
                          -slot_tab_depth])
                    cube([slot_tab_width, slot_tab_width, slot_tab_depth]);
            }

            // M5 screw clearance hole (through entire base)
            translate([base_width / 2, base_depth / 2, -slot_tab_depth - 1])
                cylinder(h = base_height + slot_tab_depth + 2, d = m5_screw_d, $fn = 32);

            // Hex nut pocket (from top, side-loading style)
            translate([base_width / 2, base_depth / 2, base_height - m5_nut_h])
                cylinder(h = m5_nut_h + 1,
                        d = (m5_nut_w + nut_pocket_tol) / cos(30),
                        $fn = 6);

            // Notch at back for nut access (rectangular cutout)
            // Allows nut to be inserted from the back
            nut_access_width = (m5_nut_w + nut_pocket_tol) / cos(30) + 2;  // Nut diameter + clearance
            translate([
                (base_width - nut_access_width) / 2,
                base_depth / 2,
                base_height - m5_nut_h
            ])
                cube([nut_access_width, base_depth / 2 + 1, m5_nut_h + 1]);
        }

        // Vertical arm at back edge - built from separate pieces
        union() {
            // Calculate window position
            window_bottom_z = base_height + arm_height - channel_height - 3;
            side_wall_thickness = (base_width - channel_width) / 2;

            // Lower wall section (below window)
            translate([0, base_depth - arm_thickness, base_height])
                cube([base_width, arm_thickness, window_bottom_z - base_height]);

            // Left side wall (beside window) - extends up to top cylinder
            translate([0, base_depth - arm_thickness, window_bottom_z])
                cube([side_wall_thickness, arm_thickness, channel_height + arm_thickness / 2]);

            // Right side wall (beside window) - extends up to top cylinder
            translate([base_width - side_wall_thickness, base_depth - arm_thickness, window_bottom_z])
                cube([side_wall_thickness, arm_thickness, channel_height + arm_thickness / 2]);

            // Cylinder at top of window (forms rounded top of window opening and continues across wall)
            translate([
                0,
                base_depth - arm_thickness / 2,
                window_bottom_z + channel_height
            ])
                rotate([0, 90, 0])
                    cylinder(h = base_width, r = arm_thickness / 2, $fn = 32);
        }

        // Minimal gussets - smaller and positioned to fit minimal base
        gusset_depth = 6;  // mm, smaller - fits on minimal base
        gusset_height = 10;  // mm, smaller but still provides support
        gusset_thickness = (base_width - channel_width) / 2;

        // Left gusset
        translate([0, base_depth, base_height])
            rotate([90, 0, 90])
                linear_extrude(height = gusset_thickness)
                    polygon([
                        [0, 0],
                        [-gusset_depth, 0],
                        [0, gusset_height]
                    ]);

        // Right gusset
        translate([base_width - gusset_thickness, base_depth, base_height])
            rotate([90, 0, 90])
                linear_extrude(height = gusset_thickness)
                    polygon([
                        [0, 0],
                        [-gusset_depth, 0],
                        [0, gusset_height]
                    ]);
    }
}

// Render single mount for preview
velcro_mount_minimal();

// Uncomment to render mirrored pair for printing
// velcro_mount_minimal();
// translate([40, 0, 0])
//     mirror([1, 0, 0])
//         velcro_mount_minimal();
