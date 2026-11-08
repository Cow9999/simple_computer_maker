# CPU Studio

CPU Studio is a browser-based digital logic editor. Build a circuit from connected components, step its clocked state, turn a selection into a reusable block, and save the complete design as portable JSON.

## Run it

Requirements: Node.js 20 or newer and npm.

On Windows, double-click **Open CPU Studio.bat** in this folder to install dependencies if needed, start the app, and open it in your browser.

```powershell
npm install
npm run dev
```

Open the local URL printed by Vite. The app stores a recovery copy in browser local storage; use **Export** for a portable project backup.

```powershell
npm test          # simulator and example CPU tests
npm run typecheck # TypeScript project checks
npm run build     # production bundle
```

## Editor controls

- Search the left palette, then drag a component onto the grid (or click to place it).
- Logic gates use the supplied schematic symbols (including NAND, XOR, and XNOR); component edges and port connection points align to the 20-pixel canvas grid. Select and wire a circuit first, then use **Make component** to save that design as a square reusable block. A single input or output sits at the block's vertical midpoint; multiple ports are evenly spaced around it. Double-click a saved block or choose **Open design** to enter its internal architecture.
- Connect a component's right-side **output** handle to a compatible left-side **input** handle. Bus widths must match and each input accepts one driver.
- Select components to edit names, values, widths, operations, initial register values, and ROM/RAM initialization. Click an input switch in the graph to change its live value.
- Shift-click or drag a selection box for multiple components. Drag to move; **Ctrl+D** duplicates the selection; **Delete** removes selected components or wires.
- Drag a blank canvas area to pan, use the arrows and horizontal/vertical position bars to navigate, and use the dotted grid to align components. Wires remain attached to their stable component/port IDs while moving nodes.
- Drag a component to the trash area in the canvas's upper-right corner to delete it and its connected wires. You can also select a component or wire and click the trash area or press **Delete**.
- **Run**, **Pause**, **Step clock**, and **Reset** control the simulator. The speed slider sets clock edges per second. A circuit with simulation errors cannot run.
- **Ctrl+Z** / **Ctrl+Shift+Z** undo and redo design edits. **Ctrl+S** saves locally. **Space** runs/pauses.
- Select a probe or output to inspect its binary, hexadecimal, unsigned, signed, and recent bounded signal history.
- The **Library** panel supports editing, renaming, duplicating, exporting, and dependency-checked deletion of custom blocks. Import a full project to import its component library.
- Open **Lessons** to follow four hands-on build chapters (Routing, Arithmetic, Sequential, and Memory), then unlock the capstone that combines those sections into one data path. Each lesson loads editable starter parts; its goal, step-by-step build instructions, and expected result also appear directly above the maker-space canvas while you work. Wire the parts yourself, simulate the result, and mark the chapter complete to track progress locally.

## Simulation semantics

- Data is an unsigned bit vector masked to the configured bus width. Signed values use two's-complement interpretation only when displayed or when a comparator is configured for signed comparison.
- Each step evaluates combinational logic, samples all registers/memories from the same pre-edge snapshot, advances one rising edge, and settles the resulting outputs. Updates therefore do not depend on component ordering.
- Every unconnected sequential `CLK` port uses the global **Step clock** edge. When a clock port is wired, that register or RAM instead updates only on a low-to-high transition; built-in clock sources toggle at each step.
- Unconnected required inputs produce explicit unknown signals and warnings. Unknown data does not silently become zero. ROM/RAM words omitted from their design-time initialization start at zero.
- Combinational loops, non-settling logic, bus-width mismatches, invalid ports, and multiple drivers are diagnosed. Registers/D flip-flops/program counters load when `EN` is high, restore their design-time initial value when `RST` is high, and otherwise hold. RAM writes on a step when `WE` is high; reads are asynchronous.
- Adder/ALU flags: **CO** is unsigned carry (for subtraction, no-borrow); **V** is signed two's-complement overflow; **Z** means the result is zero; **N** is the result's most-significant bit. An ALU with an unconnected opcode input uses its configured operation.
- Signal history is bounded to 128 clock steps. Reset discards live state and restores component initial values and memory contents; it does not modify the saved design.

## Custom components

1. Configure the bus widths and connect the component ports you want to expose.
2. Select the connected components, including the logic inside the block, and click **Make component**.
3. Give the definition a name. Inputs and outputs on the selection boundary become labeled reusable ports with the connected port's width; wires crossing the boundary are retained on the new instance.
4. Open **Library** to rename, duplicate, import/export, delete (when unused), or **Edit inside** a definition. Rename port labels there. Port widths follow the corresponding internal component ports; change those internal widths in the definition editor.
5. Drag the reusable block from **Your components** onto a circuit. Each instance has its own nested register and memory state. Nested composition is supported; recursive definitions are rejected.

Definition edits intentionally update every instance that references that definition. Keep an exported project backup before making broad definition changes.

## 8-bit CPU walkthrough

The initial project is an ordinary editable graph made from built-in ROM, PC, instruction/accumulator registers, gates, muxes, decoder, ALU, and RAM. It is not a separate CPU animation. Step the design until **HALT** lights; the accumulator and RAM address `0x0F` contain decimal `12`.

An instruction is one byte: opcode in bits 7–5, operand/address in bits 4–0.

| Opcode | Instruction | Meaning |
|---|---|---|
| `000` | `HALT` | Stop advancing the program counter |
| `001` | `LOADI iiiii` | Load the 5-bit immediate into the accumulator |
| `010` | `ADDI iiiii` | Add the immediate to the accumulator |
| `011` | `LOAD aaaaa` | Load RAM[a] into the accumulator |
| `100` | `STORE aaaaa` | Store the accumulator to RAM[a] |
| `101` | `JMP aaaaa` | Branch to address a |
| `110` | `JZ aaaaa` | Branch to a when the accumulator is zero |

The program ROM is editable from the selected ROM's inspector. Its default program is `LOADI 7`, `ADDI 5`, `STORE 15`, `HALT`; the fetch/decode/execute control is wired in the graph and can be inspected like any other design.

## Project files and recovery

Exported JSON uses the documented `cpu-studio-project` format, version `1`. It contains project name, the complete circuit graph, component positions/properties, stable wire endpoints, viewport, and all custom component definitions. It does **not** contain live simulation state: reset derives it from saved component initial values and memory contents. The runtime validates imported JSON and leaves the current project untouched on import failure. Browser storage provides automatic recovery after a refresh; explicit **Save** updates its status, while **Export** creates a downloadable `.json` file.

For the format's typed structures and extension steps, see [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md).

## Current scope

All palette component types have defined ports and simulation behavior. The editor intentionally reports unsupported/invalid graph states rather than coercing them. Custom ports are inferred from connected selection boundaries; arbitrary unconnected custom ports and per-project clock-domain configuration are not currently exposed. The CPU uses a single synchronous accumulator and a compact 5-bit immediate/address format.
