# Ham Radio Go Kit — OpenSCAD Mount Design Plan

## Project Overview

Building a ham radio go kit in a **Gator Cases 4U rack**. Two **Vevor 10" vented shelves** are used as equipment platforms. All mounts are 3D printed in PLA (case operates open-ended for airflow). Hardware is **M5 screws with washers from below**, threading into **captured M5 hex nuts** in the printed mounts. The shelf slots are used for **location only** — all load is carried by the screw/washer/nut clamping force.

---

## Physical Setup

### Shelf Layout

- **Bottom shelf** — sits on floor of case (normal orientation)
  - Kenwood TS-50S — stock mobile quick-release bracket mounted to shelf using carriage bolts through slots
  - MFJ-939 autotuner
- **Upper shelf** — mounted inverted at 3rd RU from bottom
  - Top surface (faces up toward lid): Pinebook Pro, MeanWell LRS-350-12
  - Front face: SWR meter (1U gap)
  - Bottom surface (faces down): Mirage BD-35 HT amplifier

### Loose Equipment (velcro or strap mounted)
- Dakota 10Ah LiFePO4 battery
- Buddipole PowerMini 2
- Digirig

---

## Shelf Slot Details

- Vevor 10" vented shelf
- Slot width: **8.1mm** — MEASURED WITH CALIPERS
- **NOTE:** Slot width should be a configurable parameter in OpenSCAD files for reusability with other shelves
- 3D-printed mounts use **8mm x 8mm tabs** to locate in slots
- Slot tab provides location and rotation prevention only, not structural load
- M5 washer OD is 10mm — verify clears slot edges from below

---

## Hardware Specification

| Item | Spec |
|---|---|
| Shelf mount screw | M5, length TBD by shelf thickness + mount height |
| Shelf mount nut | M5 hex, captured in print |
| Shelf mount washer | M5, 10mm OD |
| MFJ-939 chassis screws | Likely #6-32 or #8-32 US machine screws — MEASURE |

---

## File Structure

```
gokit-mounts/
├── params.scad              # all dimensions, tolerances, hardware
├── lib/
│   └── slot_mount.scad      # reusable base mount module
├── mounts/
│   ├── velcro_strap.scad    # universal velcro strap mount pair
│   ├── pinebook_l.scad      # Pinebook Pro front L-mounts (x2)
│   ├── pinebook_corner.scad # Pinebook Pro rear corner mounts (x2)
│   └── mfj939_bracket.scad  # MFJ-939 side panel brackets (x4)
```

---

## params.scad — Full Parameter List

```openscad
// ============================================================
// SHELF SLOT — MEASURED (configurable for other shelves)
// ============================================================
slot_width = 8.1;           // mm, slot opening width — MEASURED on Vevor shelf
slot_spacing = 5.0;         // mm, rail width between slots
shelf_thickness = 1.5;      // mm, shelf material thickness
slot_tab_width = 8.0;       // mm, tab width (fits in 8.1mm slot)
slot_tab_depth = 8.0;       // mm, tab depth (how far tab extends below shelf)
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
nut_pocket_tol = 0.3;       // mm, nut pocket oversize for capture

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
```

---

## Module Descriptions

### `lib/slot_mount.scad` — Base Module

Reusable foundation for all mounts. Provides:
- 8mm x 8mm slot tab sized to fit in 8.1mm shelf slots
- Shoulder/lip that bears load on shelf surface
- M5 clearance hole through body
- Hex nut pocket (side-loading) using `cylinder($fn=6)` with `cos(30)` circumradius conversion

Called by all equipment-specific mounts as their base.

### `mounts/velcro_strap.scad` — Universal Strap Mount

- Printed as a **matched pair** (mirror image)
- Each mount has slot_mount_base plus a velcro channel through the body
- Channel edges have radius to prevent velcro abrasion
- Slight inward angle on channel directs strap tension downward
- Used for: BD-35, LRS-350-12, SWR meter, battery, PowerMini 2, Digirig

### `mounts/pinebook_l.scad` — Pinebook Front L-Mounts (x2)

- Slot mount base + vertical body + horizontal arm extending over laptop top edge
- Arm clears lid thickness with `pbp_clearance` of play — retention only, not clamping
- Positioned at front left and front right
- Laptop loads by tilting front up, sliding rear into corner mounts, dropping front down under arms

### `mounts/pinebook_corner.scad` — Pinebook Rear Corner Mounts (x2)

- Slot mount base + two vertical walls at 90° forming inside corner
- Top retention arm extends inward over laptop top surface (critical — prevents pivot/lift)
- Three-sided capture: two walls + top arm
- Inside corner dimensions: `pbp_w/2` and `pbp_d` with `pbp_clearance`
- Positioned at rear left and rear right corners

### `mounts/mfj939_bracket.scad` — MFJ-939 Side Brackets (x4, 2 per side)

- L-shaped bracket: horizontal foot on shelf (slot mount base) + vertical arm against tuner side panel
- Vertical arm has clearance hole for existing chassis screws (replaced with longer screws)
- Arm height set by `mfj939_screw_height` — reaches chassis screw centerline
- Two brackets per side provide fore/aft stability
- Inside span between left and right bracket pairs set to `mfj939_chassis_w + fit_clearance`
- Tuner is captured laterally between the four brackets

---

## Measurements Required Before Modeling

All zero values in params.scad must be measured on physical hardware with calipers:

| Parameter | Item to Measure |
|---|---|
| ~~`slot_width`~~ (DONE: 8.1mm), `slot_spacing` | Vevor shelf slots |
| `shelf_thickness` | Vevor shelf material |
| `pbp_h` | Pinebook Pro closed thickness |
| `pbp_w`, `pbp_d` | Pinebook Pro footprint |
| `mfj939_chassis_w` | MFJ-939 outside chassis width |
| `mfj939_side_screw_d` | MFJ-939 chassis screw diameter/thread |
| `mfj939_side_screw_spacing` | MFJ-939 fore/aft screw hole spacing on side panel |
| `mfj939_screw_height` | MFJ-939 screw centerline height above shelf surface |

---

## Print Notes

- **Material:** PLA acceptable — case operates open-ended, heat not a concern
- **Nut pockets:** Side-loading preferred for assembly ease; print slightly undersized for press fit
- **Slot tabs:** Orient vertically in slicer for best layer adhesion against shear
- **Infill:** 40%+ for bracket arms; 20% acceptable for strap mount bodies
- **Test print:** Print `slot_mount_base` test piece and verify fit in shelf slots before printing full mounts

---

## Assembly Notes

- Velcro strap mounts: place pair, drop nuts in pockets, feed M5 + washer from below, snug down, thread velcro strap through both mounts and over gear
- Pinebook: install rear corner mounts first, tilt laptop to seat rear corners, drop front under L-mount arms, confirm top retention arms engage on all four mounts
- MFJ-939: install bracket pairs aligned to chassis screw holes, set tuner in position between brackets, drive longer chassis screws through bracket arms into side panels
