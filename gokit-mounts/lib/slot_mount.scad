// ============================================================
// Slot Mount Base Module
// ============================================================
// Reusable foundation for all shelf mounts
// Provides slot tab, mounting surface, M5 hole, and nut pocket

include <../params.scad>

module slot_mount_base() {
    // Horizontal base that sits on top of shelf
    // Need enough width for: slot tab + walls around nut pocket + channel side walls
    // Increased width provides more robust walls on sides of velcro channel
    base_width = 28;  // mm, provides 10mm wall on each side of slot tab
    base_depth = mount_body_d;
    base_height = mount_body_h;

    difference() {
        union() {
            // Main horizontal base body
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
        // Using cos(30) to convert across-flats to circumradius
        translate([base_width / 2, base_depth / 2, base_height - m5_nut_h])
            cylinder(h = m5_nut_h + 1,
                    d = (m5_nut_w + nut_pocket_tol) / cos(30),
                    $fn = 6);
    }
}

// Test render
slot_mount_base();
