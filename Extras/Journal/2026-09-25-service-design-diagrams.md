# 2026-09-25 Service Design Diagrams

The command and environment design document was brought up to date with the
finished service design and illustrated with three Excalidraw diagrams: the
service shape, the service dependency map, and the service surfaces with the
views that observe each `State`. The service shape diagram replaces the
document's earlier text diagram. The document also gained a service table and
the rule that command availability reads only observable state.

The drawings live in a Bookish collection in Excalidraw+, created through the
Excalidraw MCP. The repository holds each scene's `.excalidraw` source and a
PNG render under `Extras/Documentation/Diagrams/`.

GitHub Markdown cannot embed a live Excalidraw scene. SVG export through
Excalidraw's own `exportToSvg` worked, but the MCP has no file export of its
own. PNGs from the MCP's `take_screenshot` were chosen instead: they need no
extra tooling and are bounded at 1920×1080. That bound favours wide layouts, so
the surfaces diagram was re-laid out top to bottom.
