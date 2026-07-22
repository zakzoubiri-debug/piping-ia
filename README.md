# EngHub – Smart Line Builder

An MVP web app for piping designers to sketch and sanity-check a piping line
before modelling it in E3D, SP3D, AutoCAD Plant 3D, or another CAD tool.

## Run it

```bash
npm install
npm run dev
```

Then open http://localhost:3000

## What's included

- Left sidebar with a searchable component library (equipment, valves,
  fittings, instruments, utilities)
- Line Information form with the default demo values pre-filled
- A piping line canvas seeded with a default demo line (pump → gate valve →
  check valve → flow meter → control valve → heat exchanger)
- Automatic flange/gasket accessory nodes around flanged components
- An editable properties panel per component (tag, type, connection type,
  size, pressure class, manufacturer, notes)
- "Analyze Line" running 10 local preliminary design checks, grouped by
  Critical / Warning / Information / Passed in the right-hand panel
- Save (localStorage, auto-restored on reload), Clear Line, Reset Demo,
  Duplicate, and JSON Export
- Toast notifications for add / remove / save / analyze actions

## Notes

The engineering checks in this MVP are preliminary design prompts meant to
flag items for review — they are not certified calculations and do not
replace a qualified engineering review against your project specifications
and applicable codes.
