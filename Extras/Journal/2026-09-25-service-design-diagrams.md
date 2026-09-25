# 2026-09-25 Service Design Diagrams

The service documentation was brought up to date and split in two. The command
and environment design document now describes only the design: the engine and
commander, commands and `Access` protocols, the service shape, and the view and
environment rules. Its earlier text diagram was replaced by an Excalidraw
service-shape diagram. The new application services document lists each
service's purpose, `State`, `API`, and collaborators, with diagrams of the
service dependencies and of the views that observe each `State`, the temporary
browser refresh, and the source layout.

The drawings live in a Bookish collection in Excalidraw+, created through the
Excalidraw MCP. The repository holds each scene's `.excalidraw` source and a
PNG render under `Extras/Documentation/Diagrams/`.

GitHub Markdown cannot embed a live Excalidraw scene. SVG export through
Excalidraw's own `exportToSvg` worked, but the MCP has no file export of its
own. PNGs from the MCP's `take_screenshot` were chosen instead: they need no
extra tooling and are bounded at 1920×1080. That bound favours wide layouts, so
the surfaces diagram was re-laid out top to bottom.
