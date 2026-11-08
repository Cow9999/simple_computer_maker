# Developer guide

## Project map

| Path | Responsibility |
|---|---|
| `src/App.tsx` | React editor, graph interaction, inspector, simulation controls, and project/library actions |
| `src/styles.css` | Editor workspace, component nodes, inspector, and dialog styles |
| `src/core/model.ts` | Serializable circuit, custom definition, signal, and simulation-state interfaces |
| `src/core/catalog.ts` | Palette metadata, built-in port layouts, bus-width normalization, and bit masks |
| `src/core/simulator.ts` | Pure validation, combinational settling, sequential edge updates, hierarchy, and signal formatting |
| `src/core/customComponents.ts` | Selection wrapping, fresh-ID duplication, and definition dependency checks |
| `src/core/persistence.ts` | Versioned JSON validation/round-trip and browser-local save/recovery |
| `src/examples/cpu.ts` | Editable CPU graph, instruction encoding, and example runner built on the general simulator |
| `src/examples/lessons.ts` | Guided course chapters, wiring exercises, and editable starter circuits |
| `src/core/simulator.test.ts` | Direct tests of gates, arithmetic, state, memories, hierarchy, persistence, and CPU result |
| `src/main.tsx` / `index.html` | Browser entry points |

## Dependencies

- **React / React DOM** provide the editor UI and component state.
- **@xyflow/react** provides graph selection, pan/zoom, draggable nodes, port handles, and editable graph connections. Circuit data remains independent of React Flow's runtime node objects.
- **Vite** serves and bundles the TypeScript application; **TypeScript** checks the strict application types.
- **Vitest** runs the simulator directly in Node without rendering the browser UI.
- **lucide-react** supplies the small consistent editor icon set.

## Add a built-in component

1. Add its type, label, category, and design defaults in `COMPONENT_CATALOG` in `src/core/catalog.ts`.
2. Add its stable, direction-aware ports to `portsFor`. Port IDs are persisted in wires; changing an existing port ID requires a project-format migration.
3. Implement its behavior in `evaluateBuiltin` in `src/core/simulator.ts`. Use `knownSignal`/`maskValue` for unsigned results and `unknownSignal` for missing or unknown data; never substitute zero for an unknown input.
4. If it has state, add its design-derived initialization in `createInitialSimulationState` and calculate its next value in `stepSimulation`. Read only the settled pre-edge input snapshot, then write the new value to the next-state copy.
5. Add a direct simulator test in `src/core/simulator.test.ts`. The `buffer` gate is a minimal example of a stateless, single-input component; copy its catalog entry, port definition, evaluator case, and test when adding another simple logic component.

## Add an ALU operation

The ALU opcode mapping and operation switch are in `aluOperation` and the `type === 'alu'` branch of `evaluateBuiltin` in `src/core/simulator.ts`. Add the operation's stable name/opcode, its unsigned result, carry/overflow behavior where meaningful, and a test for result masking and flags. Update the ALU operation selector and instruction documentation in `src/App.tsx`, `README.md`, and the help dialog when the operation changes the user-visible contract. Current operation names are `ADD`, `SUB`, `AND`, `OR`, `XOR`, `NOT`, `SHL`, and `SHR`; shift operations shift by one bit.

## Change simulation behavior

Keep all runtime logic in `src/core/simulator.ts` and all immutable design/runtime shapes in `src/core/model.ts`. `evaluateSimulation` validates and settles combinational outputs without mutating its inputs. `stepSimulation` samples settled state once, constructs next state, advances the tick, then settles again. Add tests for both pre-edge and post-edge values when changing clock/state rules. `SimulationState.history` is intentionally bounded; adjust `HISTORY_LIMIT` together with the inspector's waveform display if that limit changes.

## Modify the interface

`src/App.tsx` owns editor state transitions and passes serializable components/wires to the canvas. `CircuitNodeView` renders stable port IDs as React Flow handles; its 200-pixel built-in node edges and 40-pixel-spaced port rows align to the 20-pixel canvas grid. A saved custom definition is displayed as a square whose port rows are centered and spread evenly on each side. `CircuitCanvas` translates a user connection into a `CircuitWire` and hit-tests the pointer against its trash drop target at drag end; deletion uses the normal selection path so attached wires and undo history stay consistent. `Inspector` edits saved component properties. Keep React Flow-specific shapes at this boundary. Add presentation styles in `src/styles.css`; do not store live signal values in the project document.

The guided course content and component-only lesson starter graphs live in `src/examples/lessons.ts`. Keep its port IDs, widths, initial values, wiring instructions, and expected results consistent. The active lesson's goal, full build-step list, and expected result are also displayed in a collapsible guide directly above the maker-space canvas in `CircuitCanvas`. Lesson completion is a self-check persisted separately in browser local storage; the graph templates use the same editor models and simulator as hand-built circuits. The capstone stays locked until the four section lessons are marked complete.

## Extend custom components

`CustomComponentDefinition` in `src/core/model.ts` stores an internal graph and boundary mappings from external port IDs to internal component/port IDs. `wrapSelectionAsCustom` moves internal wires to the definition and retargets crossing parent wires. The simulator evaluates nested graphs recursively and prefixes runtime state keys with each instance path so separate instances cannot share register/memory state. Preserve these mappings when adding definition editing or migrating the format, and reject recursion before committing a library update.

## Extend the project format

`CircuitProject` in `src/core/model.ts` is the canonical version-1 JSON shape. `src/core/persistence.ts` checks the format/version, unique IDs, required graph data, and circuit/definition validity before returning imported data. To make a breaking persisted-shape change:

1. Increment `CircuitProject.version` and define the new serializable fields.
2. Add an explicit migration path for supported older versions in `parseProject`; never evaluate imported code.
3. Keep runtime simulation state outside the project unless a field is truly part of the design's initial state.
4. Add an export/import round-trip test and malformed-file test before updating the README format notes.

## Rebuild and verify

Install Node.js 20+ and npm, run `npm install`, then start the editor using `npm run dev`. Before distributing changes, run `npm test`, `npm run typecheck`, and `npm run build`.
