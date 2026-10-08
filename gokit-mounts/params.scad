// ============================================================
// Ham Radio Go Kit — OpenSCAD Parameters
// ============================================================

// ============================================================
// SHELF SLOT — MEASURED (configurable for other shelves)
// ============================================================
slot_width = 8.0;           // mm, slot opening width — MEASURED (long rails)
slot_spacing = 12.0;        // mm, rail width between slots — MEASURED
slot_pitch = slot_width + slot_spacing;  // mm, slot center-to-center (20.0)
shelf_thickness = 1.5;      // mm, shelf material thickness
slot_tab_width = 7.6;       // mm, tab width (0.4mm clearance in an 8mm slot)
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
// ANTUNER AT-100M PRO — MEASURED
// ============================================================
antuner_w = 74.0;           // mm, width (front panel with screen/power/tune)
antuner_h = 29.0;           // mm, height (front panel)
antuner_d = 154.0;          // mm, front-to-back case depth
antuner_ctrl_top = 6.0;     // mm, screen/tune buttons offset down from top edge
antuner_fit = 1.0;          // mm, clearance between tuner side and cradle wall

// ============================================================
// SHELF FRONT LIP
// ============================================================
shelf_lip_h = 15.3;         // mm, front lip height that blocks the controls — MEASURED

// ============================================================
// ANTUNER HANGING SPACER (mounts to shelf slots, tuner hangs below lip)
// ============================================================
antuner_drop = shelf_lip_h + 3.0;      // mm, tuner top below shelf underside (clears lip)
antuner_wall = 4.0;                    // mm, cradle wall thickness
antuner_plate_t = 5.0;                 // mm, top frame thickness (4mm nut pocket + 1mm skin)
antuner_cradle_len = 74.0;             // mm, cradle band along the tuner (sits mid-tuner)
antuner_foot = 3.0;                    // mm, wall extension below tuner bottom
antuner_channel_h = 6.0;               // mm, upper strap window height
antuner_channel_w = 22.0;              // mm, strap slot / window width
antuner_strap_y = 20.0;                // mm, strap positions each side of cradle center
antuner_ledge = 4.0;                   // mm, register ledge the tuner top rests against
antuner_ledge_t = 3.0;                 // mm, register ledge thickness
antuner_bar_h = 11.0;                  // mm, half-depth of the central tab bar (Y)
antuner_rail_w = 8.0;                  // mm, front/back frame rail width (Y)
antuner_window_h = 9.0;                // mm, upper strap window height (Z)
antuner_tab_h = shelf_thickness + 0.5; // mm, slot tab height (up into the slot)
antuner_tab_x = 20.0;                  // mm, tab offset X, directly above the tuner; must land on a rail — MEASURE

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
