# License and Attribution Notices

This package is a local Pi extension package created for this dotfiles repository.

## Vendored/adapted upstream concepts and code

The implementation vendors or adapts concepts and source patterns from the following MIT-licensed Pi packages:

### `tintinweb/pi-subagents`

- Repository: <https://github.com/tintinweb/pi-subagents>
- Package: `@tintinweb/pi-subagents`
- License: MIT
- Copyright: Copyright (c) 2026 tintinweb
- Adapted areas: agent markdown discovery, Claude Code-style subagent orchestration tool surface (`subagent`, `get_subagent_result`, `steer_subagent` in this package), isolated child-session launch model, background run state, and custom agent runtime options.

MIT notice requirement:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

### `MasuRii/pi-permission-system`

- Repository: <https://github.com/MasuRii/pi-permission-system>
- Package: `pi-permission-system`
- License: MIT
- Copyright: Copyright (c) 2026 MasuRii
- Adapted areas: agent-local `permission:` frontmatter model, deterministic permission states, tool-call gating, bash/file-specific checks, approval prompts, forwarding/runtime context ideas, and audit/explain behhttps://github.com/gotgenes/pi-permission-system/blob/main/docs/event-api.mdavior.

MIT notice requirement:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

## MIT License text

Permission is hereby granted, free of charge, to any person obtaining a copy of the relevant Software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the condition that the copyright notice and permission notice are included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
