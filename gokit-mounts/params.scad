// ============================================================
// Ham Radio Go Kit — OpenSCAD Parameters
// ============================================================

// ============================================================
// SHELF SLOT — MEASURED (configurable for other shelves)
// ============================================================
slot_width = 8.1;           // mm, slot opening width — MEASURED on Vevor shelf
slot_spacing = 5.0;         // mm, rail width between slots
shelf_thickness = 1.5;      // mm, shelf material thickness
slot_tab_width = 8.0;       // mm, tab width (fits in 8.1mm slot)
slot_tab_depth = 1.0;       // mm, tab depth - just prevents rotation, allows washer clearance
slot_tab_engage = 2.0;      // mm, minimum engagement depth for retention

// ============================================================
// M5 HARDWARE
// ============================================================
m5_screw_d = 5.2;           // mm, clearance hole diameter
m5_nut_w = 8.0;             // mm, hex nut width across flats
m5_nut_h = 4.0;             // mm, hex nut height
m5_washer_od = 10.0;        // mm, washer OD - verify clears slot

// ============================================================
// TOLERANCES
// ============================================================
fit_clearance = 0.2;        // mm, slot tab fit clearance
nut_pocket_tol = 0.1;       // mm, nut pocket oversize for capture (reduced to prevent rotation)

// ============================================================
// VELCRO STRAP MOUNTS
// ============================================================
velcro_width = 19.05;       // mm, 0.75" velcro - standardize all straps
velcro_channel_clearance = 1.0;  // mm, channel oversize
mount_body_w = 25.0;        // mm
mount_body_d = 25.0;        // mm
mount_body_h = 8.0;         // mm, sets max gear height that can be strapped

// ============================================================
// PINEBOOK PRO — measure closed unit with calipers
// ============================================================
pbp_w = 280.0;              // mm, width
pbp_d = 192.0;              // mm, depth
pbp_h = 12.0;               // mm, closed lid thickness — MEASURE
pbp_clearance = 0.5;        // mm, fit clearance inside captures

// L-mount (front, x2)
l_arm_thickness = 4.0;      // mm, horizontal arm thickness
l_arm_length = 15.0;        // mm, how far arm extends over laptop top

// Corner mount (rear, x2)
corner_wall_thickness = 4.0;  // mm
corner_wall_h = 20.0;         // mm, should be > pbp_h + corner_arm_thickness
corner_arm_length = 15.0;     // mm, top retention arm extends over laptop
corner_arm_thickness = 4.0;   // mm

// ============================================================
// MFJ-939 BRACKETS — measure on physical unit
// ============================================================
mfj939_chassis_w = 0.0;        // mm, outside width — MEASURE
mfj939_side_screw_d = 3.5;     // mm, #6-32 clearance hole — VERIFY
mfj939_side_screw_spacing = 0.0; // mm, fore/aft spacing between screw holes on side panel — MEASURE
mfj939_screw_height = 0.0;     // mm, screw centerline height above shelf surface — MEASURE

// Bracket geometry
bracket_foot_d = 25.0;         // mm, horizontal foot depth on shelf
bracket_foot_h = 8.0;          // mm, horizontal foot thickness
bracket_arm_thickness = 4.0;   // mm, vertical arm thickness
