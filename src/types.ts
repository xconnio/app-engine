// The manifest shape an app-engine app registers with deskconnd (as YAML, validated and
// converted to JSON there). Framework-agnostic: consumed by any renderer for any language.

export interface ManifestEvent {
  call: string
  result?: string
}

export interface ManifestElement {
  /** HTML tag name (e.g. "div", "span", "button", "input") — the manifest determines
   * markup directly, the renderer contributes no layout or type semantics of its own. */
  tag: string
  id?: string
  text?: string
  /** Arbitrary CSS properties (e.g. `display: "flex"`, `color: "#fff"`) applied as
   * inline style — the manifest determines look directly, the renderer contributes none. */
  style?: Record<string, string>
  children?: ManifestElement[]
  on?: Record<string, ManifestEvent>
}

export interface Manifest {
  id: string
  name: string
  icon: string
  root: ManifestElement
}

export interface AppSummary {
  id: string
  name: string
  icon: string
}
