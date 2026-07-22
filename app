@tailwind base;
@tailwind components;
@tailwind utilities;

html,
body {
  height: 100%;
}

body {
  @apply bg-panel text-steel-100 antialiased;
}

* {
  scrollbar-width: thin;
  scrollbar-color: #374f5f #12181f;
}

*::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

*::-webkit-scrollbar-track {
  background: #12181f;
}

*::-webkit-scrollbar-thumb {
  background-color: #374f5f;
  border-radius: 9999px;
}

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EngHub – Smart Line Builder",
  description:
    "Build and analyze an industrial piping line before modelling it in your CAD tool.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

"use client";

import { useEffect, useRef, useState } from "react";
import Topbar from "@/components/Topbar";
import ComponentSidebar from "@/components/ComponentSidebar";
import LineInformationForm from "@/components/LineInformationForm";
import LineCanvas from "@/components/LineCanvas";
import ComponentPropertiesModal from "@/components/ComponentPropertiesModal";
import AnalysisPanel from "@/components/AnalysisPanel";
import Toast from "@/components/Toast";
import { getDefinition } from "@/lib/component-library";
import { analyzeLine } from "@/lib/analysis-engine";
import { loadLine, saveLine } from "@/lib/storage";
import { downloadLineExport } from "@/lib/export-json";
import {
  AnalysisState,
  ComponentDefinition,
  LineComponent,
  LineData,
  ToastMessage,
  ToastVariant,
} from "@/types/engineering";

const DEFAULT_LINE_DATA: LineData = {
  lineNumber: "10-P-101-A1",
  fromEquipment: "P-101",
  toEquipment: "E-101",
  fluid: "Process Water",
  pipeSpec: "CS150",
  nominalDiameter: "DN100",
  pressure: "10 bar",
  temperature: "80 °C",
  lineLength: "20 m",
  insulation: "No",
};

function makeInstanceId(): string {
  return `lc-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function nextTagNumber(components: LineComponent[], prefix: string): number {
  const numbers = components
    .filter((c) => c.tag.startsWith(`${prefix}-`))
    .map((c) => parseInt(c.tag.split("-").pop() || "100", 10))
    .filter((n) => !isNaN(n));
  const max = numbers.length > 0 ? Math.max(...numbers) : 100;
  return max + 1;
}

function componentFromDefinition(
  definition: ComponentDefinition,
  existing: LineComponent[],
  overrideTag?: string
): LineComponent {
  const number = nextTagNumber(existing, definition.tagPrefix);
  return {
    instanceId: makeInstanceId(),
    typeId: definition.typeId,
    name: definition.name,
    category: definition.category,
    icon: definition.icon,
    tag: overrideTag ?? `${definition.tagPrefix}-${number}`,
    connectionType: definition.defaultConnectionType,
    size: "",
    pressureClass: "",
    manufacturer: "",
    notes: "",
    isIsolationValve: definition.isIsolationValve,
  };
}

function buildDefaultComponents(): LineComponent[] {
  const order = [
    { typeId: "pump", tag: "P-101" },
    { typeId: "gate-valve", tag: "XV-101" },
    { typeId: "check-valve", tag: "NRV-101" },
    { typeId: "flow-meter", tag: "FT-101" },
    { typeId: "control-valve", tag: "FCV-101" },
    { typeId: "heat-exchanger", tag: "E-101" },
  ];

  const components: LineComponent[] = [];
  for (const item of order) {
    const definition = getDefinition(item.typeId);
    if (!definition) continue;
    components.push(componentFromDefinition(definition, components, item.tag));
  }
  return components;
}

export default function SmartLineBuilderPage() {
  const [lineData, setLineData] = useState<LineData>(DEFAULT_LINE_DATA);
  const [components, setComponents] = useState<LineComponent[]>([]);
  const [analysis, setAnalysis] = useState<AnalysisState | null>(null);
  const [activeIndex, setActiveIndex] = useState<number | null>(null);
  const [toasts, setToasts] = useState<ToastMessage[]>([]);
  const hasLoaded = useRef(false);

  // Load any saved line on first mount; otherwise seed the default demo line.
  useEffect(() => {
    if (hasLoaded.current) return;
    hasLoaded.current = true;

    const saved = loadLine();
    if (saved) {
      setLineData(saved.lineData);
      setComponents(saved.components);
      setAnalysis(saved.analysis);
    } else {
      setComponents(buildDefaultComponents());
    }
  }, []);

  function pushToast(text: string, variant: ToastVariant = "info") {
    const toast: ToastMessage = { id: makeInstanceId(), text, variant };
    setToasts((prev) => [...prev, toast]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== toast.id));
    }, 3200);
  }

  function handleLineDataChange(field: keyof LineData, value: string) {
    setLineData((prev) => ({ ...prev, [field]: value as never }));
  }

  function handleAddComponent(definition: ComponentDefinition) {
    setComponents((prev) => [...prev, componentFromDefinition(definition, prev)]);
    pushToast(`${definition.name} added to line.`, "success");
  }

  function handleAddComponentByTypeId(typeId: string) {
    const definition = getDefinition(typeId);
    if (!definition) return;
    handleAddComponent(definition);
  }

  function handleRemoveComponent(index: number) {
    const removed = components[index];
    setComponents((prev) => prev.filter((_, i) => i !== index));
    if (removed) pushToast(`${removed.tag} removed from line.`, "info");
  }

  function handleMoveComponent(index: number, direction: -1 | 1) {
    setComponents((prev) => {
      const target = index + direction;
      if (target < 0 || target >= prev.length) return prev;
      const next = [...prev];
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  }

  function handleDuplicateComponent(index: number) {
    setComponents((prev) => {
      const source = prev[index];
      const definition = getDefinition(source.typeId);
      if (!definition) return prev;
      const duplicate = componentFromDefinition(definition, prev);
      const next = [...prev];
      next.splice(index + 1, 0, { ...duplicate, ...pickEditableFields(source), instanceId: duplicate.instanceId, tag: duplicate.tag });
      return next;
    });
    pushToast("Component duplicated.", "success");
  }

  function pickEditableFields(source: LineComponent) {
    return {
      connectionType: source.connectionType,
      size: source.size,
      pressureClass: source.pressureClass,
      manufacturer: source.manufacturer,
      notes: source.notes,
    };
  }

  function handleSaveComponentProperties(updated: LineComponent) {
    setComponents((prev) =>
      prev.map((c) => (c.instanceId === updated.instanceId ? updated : c))
    );
    setActiveIndex(null);
    pushToast(`${updated.tag} updated.`, "success");
  }

  function handleClearLine() {
    setComponents([]);
    setAnalysis(null);
    pushToast("Line cleared.", "info");
  }

  function handleResetDemo() {
    setLineData(DEFAULT_LINE_DATA);
    setComponents(buildDefaultComponents());
    setAnalysis(null);
    pushToast("Demo line restored.", "success");
  }

  function handleAnalyze() {
    const result = analyzeLine(lineData, components);
    setAnalysis(result);
    const { critical, warnings } = result.summary;
    if (critical > 0) {
      pushToast(
        `Analysis complete: ${critical} critical issue(s) found.`,
        "error"
      );
    } else if (warnings > 0) {
      pushToast(
        `Analysis complete: ${warnings} warning(s) to review.`,
        "info"
      );
    } else {
      pushToast("Analysis complete: line approved.", "success");
    }
  }

  function handleSave() {
    saveLine(lineData, components, analysis);
    pushToast("Line saved locally.", "success");
  }

  function handleExport() {
    downloadLineExport(lineData, components, analysis);
    pushToast("Export downloaded.", "success");
  }

  const activeComponent =
    activeIndex !== null ? components[activeIndex] : null;

  return (
    <div className="flex h-screen flex-col bg-panel">
      <Topbar
        projectName="Demo Refinery Project"
        onSave={handleSave}
        onExport={handleExport}
      />

      <div className="flex flex-1 overflow-hidden">
        <ComponentSidebar onAddComponent={handleAddComponent} />

        <div className="flex flex-1 flex-col overflow-hidden">
          <LineInformationForm
            lineData={lineData}
            onChange={handleLineDataChange}
          />
          <LineCanvas
            components={components}
            onOpenComponent={setActiveIndex}
            onRemoveComponent={handleRemoveComponent}
            onMoveComponent={handleMoveComponent}
            onDuplicateComponent={handleDuplicateComponent}
            onAddComponentByTypeId={handleAddComponentByTypeId}
            onClearLine={handleClearLine}
            onResetDemo={handleResetDemo}
            onAnalyze={handleAnalyze}
          />
        </div>

        <AnalysisPanel analysis={analysis} />
      </div>

      {activeComponent && (
        <ComponentPropertiesModal
          component={activeComponent}
          onClose={() => setActiveIndex(null)}
          onSave={handleSaveComponentProperties}
        />
      )}

      <Toast toasts={toasts} />
    </div>
  );
}
