# OpenDotlet parts list

Working bill of materials for the proposed physical console. Updated 10 November 2026.

**Status: planning list, not a purchase-ready or electrically validated build.** The supported gallery board below is established by this repository. The console components are candidates from the build discussion; exact physical revisions, wiring and compatibility still need verification. Quantities describe the proposed build unless explicitly marked as reported inventory. Prices, stock and ownership are not inferred.

## 1. Existing supported gallery baseline

| Part | Quantity for one gallery device | Evidence / limits |
| --- | --- | --- |
| Waveshare ESP32-S3-Touch-LCD-1.46 | 1 | Repository-supported board: ESP32-S3, SPD2010 412 × 412 round LCD, 16 MB flash and 8 MB PSRAM. See [hardware notes](HARDWARE.md) and [vendor documentation](https://docs.waveshare.com/ESP32-S3-Touch-LCD-1.46). |
| USB data cable | 1 | Power/programming connection; select connectors to match the actual board and host. A charge-only cable is insufficient for flashing. |
| Development computer | 1, reusable | Required to build/flash; see [Quickstart](QUICKSTART.md). Not a separate purchase requirement. |

This does not establish that the same board is the display intended for the console. The discussed **Waveshare 1.43-inch screen is a separate, unconfirmed candidate**, not an alias for the supported 1.46-inch board. Do not order or flash it on that assumption.

## 2. Proposed console controls and display

| Component | Proposed quantity / inventory | Identification and next check |
| --- | --- | --- |
| [Adafruit NeoKey 5×6 Ortho Snap-Apart PCB](https://learn.adafruit.com/adafruit-neokey-5x6-ortho-snap-apart) | 1 candidate sheet; count on hand unverified | The full sheet has 30 key positions. Proposed console uses 20; confirm geometry and routing before separating the PCB. Exact physical board/revision remains unverified. |
| MX-compatible mechanical switches | 20 for the proposed 20-key layout | Proposed requirement, not a confirmed inventory count. NeoKey switches are sold separately. Select exact switch model; Kailh low-profile switches do not fit this board. |
| Matching keycaps | 20 for the proposed 20-key layout | Proposed requirement, not a confirmed inventory count. Select stem compatibility, sizes and legends after layout approval. Keycaps are not included with the NeoKey PCB. |
| Seeed Studio XIAO microcontroller boards | 5 reported available; number used TBD | Described as “C5”; photo-based candidate is C6. **Exact MCU/model is unconfirmed.** Read board markings and verify official pinout before selecting firmware, assigning GPIO or assuming USB HID support. Five available boards do not imply five are required. |
| Waveshare round display / development board | Quantity TBD | “1.43-inch” candidate from discussion. Exact product name, controller, interface, touch support and whether it includes an MCU are unconfirmed. Keep separate from the supported 1.46-inch gallery board above. |
| [Axiometa rotary encoder, AX22-0003](https://www.axiometa.io/products/rotary-encoder) | Quantity TBD | Candidate identification. Vendor describes quadrature rotary input with push button. Confirm module revision, connector and pinout on the actual part. |
| [Grove Rotary Angle Sensor](https://wiki.seeedstudio.com/Grove-Rotary_Angle_Sensor/) | Quantity TBD | Candidate identification; verify standard versus panel-mount version. This is an analog potentiometer, not an endless rotary encoder. Output can approach its supply voltage; confirm ADC limits and any required voltage conditioning before connection. |

The vendor links identify product families and specifications, not proof that a photographed part is that exact revision. Axiometa and Grove controls are distinct options/controls, not interchangeable electrical replacements.

## 3. Integration parts still to select

| Item | Quantity | Selection gate |
| --- | --- | --- |
| Controller breakout / adapter board(s) | TBD | Match confirmed XIAO model and the connections needed by the keyboard, dials and display. No adapter SKU is selected. |
| Grove cable / breakout | TBD | Match the actual sensor connector and signal pinout. Connector shape alone does not establish voltage compatibility. |
| Headers, hookup wire and suitable connectors | TBD | Derive from a reviewed wiring diagram, mounting arrangement and serviceability needs. |
| USB data cables and, if needed, powered USB hub | TBD | Count only the devices that will actually connect to the host; verify data support and total power demand. |
| USB power source / distribution | TBD | Size after measuring or budgeting display, MCU and NeoPixel loads, including peak brightness. Do not assume a single board's regulator can power everything. |
| Logic-level conversion / analog conditioning | Conditional; TBD | Select only after confirming signal levels, ADC maximums and power domains. |
| Host / companion computer | 1 proposed, reusable; exact host TBD | Intended for future console/agent integration. The existing offline gallery does not require a continuously connected host or API account. |
| Enclosure, backplate, standoffs, screws and dial knob(s) | TBD | Measure actual boards, key spacing, switch retention, shaft and clearances before specifying sizes or printing a case. |

A battery, charger, extra microphone or speaker is **not specified** by this list. The current gallery does not validate the supported board's audio or battery functions.

## 4. Before buying, cutting or wiring

- [ ] Record the exact model/revision of every XIAO and the proposed Waveshare display.
- [ ] Count the parts already on hand; keep inventory separate from build quantities.
- [ ] Confirm the 20-key layout. A full 5×6 layout would instead need 30 switches and 30 keycaps.
- [ ] Decide which controller handles keys, lighting, dials and display; verify GPIO availability and transport to the host.
- [ ] Draw the wiring and power plan. NeoKey requires row/column scanning plus a separate NeoPixel signal; it is not a self-contained USB keyboard.
- [ ] Check connector pinouts, common ground, logic voltages, ADC limits and peak current before connecting modules.
- [ ] Validate each component separately, then the combined prototype, before finalizing enclosure dimensions.
- [ ] Replace each TBD with a verified SKU, required count and sourcing link only after the design is confirmed.

## Sources and scope

- [Supported hardware](HARDWARE.md), [current verification](VERIFICATION.md), [architecture](ARCHITECTURE.md) and [roadmap](ROADMAP.md) define what the existing repository supports.
- [Adafruit NeoKey guide](https://learn.adafruit.com/adafruit-neokey-5x6-ortho-snap-apart), [Axiometa AX22-0003](https://www.axiometa.io/products/rotary-encoder) and [Seeed Grove sensor documentation](https://wiki.seeedstudio.com/Grove-Rotary_Angle_Sensor/) were consulted for the candidate component families.
- The five-board inventory report, 20-key layout and unconfirmed part identifications come from the project build discussion. They are not results of physical inspection or integration tests.

This documentation does not add firmware support for the candidate console hardware or change the existing supported board.
