# Spec: Codex Generated Compatibility Layer

**Status:** Draft
**Owner:** Reid W
**Created:** 2026-04-18 14:02:24 PDT
**Complexity:** MEDIUM
**Branch:** codex-setup

---

## Business Goals

### Why This Matters

This repository already has a populated `claude-pack/` with workflows, agents, hooks, rules, and supporting scripts. The current friction is that Codex support appears to require either a parallel hand-maintained `codex-pack/` or a one-off migration that forks the source of truth. That creates duplicate maintenance burden and invites drift.

The goal is to make Codex support installable without introducing a second maintained pack. `claude-pack/` remains the canonical authored content, and Codex-native assets are generated from it as a compatibility layer.

### Success Criteria

- [ ] `claude-pack/` remains untouched as the authored source of truth
- [ ] Codex-native assets can be generated from existing Claude assets
- [ ] Users can install the generated Codex assets into `~/.codex/` with one script
- [ ] High-value workflows are available in Codex as prompts, skills, and subagents where appropriate
- [ ] Memory-specific features are explicitly excluded for this phase
- [ ] The generated Codex layer is deterministic and can be rebuilt at any time

### Priority

P1 - Important infrastructure enabling Codex adoption without increasing maintenance cost.

---

## Problem Statement

### Current State

The repository has a mature `claude-pack/` and project workflow, but no agreed Codex support model that satisfies all of these constraints:

1. No hand-maintained parallel `codex-pack/`
2. No edits to `claude-pack/`
3. Same conceptual workflows available in Codex
4. No investment in transcript memories right now

The compatibility research identified rough feature mappings, but the proposed parallel `codex-pack/` would still create a second maintained distribution surface. That is explicitly not desired.

### Desired Outcome

Add a generated Codex compatibility layer that:

1. Treats `claude-pack/` as immutable input
2. Produces Codex-native artifacts in a generated output directory
3. Installs those artifacts into `~/.codex/`
4. Excludes memory-dependent features until a separate memory design exists

The resulting user model should be:

- Edit or add authored content in `claude-pack/`
- Run a build/install script
- Use the equivalent workflows in Codex

---

## Scope

### In Scope

1. **Generated Codex distribution**
   - Generate Codex-native prompts, agents, rules, hooks, and skills from `claude-pack/`
   - Write generated output to a dedicated, non-authored directory

2. **Codex command/workflow compatibility**
   - Convert supported Claude commands into Codex prompt files
   - Preserve command intent and workflow instructions

3. **Codex subagent compatibility**
   - Convert supported Claude agents into Codex custom agent files

4. **Rules and hook compatibility**
   - Consolidate Claude rules into Codex `AGENTS.md`
   - Generate Codex hook configuration from existing hook scripts where applicable

5. **Codex installation workflow**
   - Provide a one-command setup path for `~/.codex/`
   - Keep installation idempotent and non-destructive where possible

6. **Explicit exclusions for phase 1**
   - Exclude memory-related commands, hooks, and agents from Codex generation

### Out of Scope

- Editing or restructuring `claude-pack/`
- Designing or implementing a Codex memory/recall system
- Full behavioral parity with Claude transcript workflows
- Replacing existing Claude setup scripts
- Publishing as a Codex plugin or marketplace package
- Windows-specific support guarantees

### Edge Cases & Considerations

1. **Claude formats are not Codex-native:** generated wrappers will need Codex-specific metadata and file layouts
2. **Not every Claude command should become a Codex skill:** most user-invoked workflows should become prompts instead
3. **Some features are Claude-specific:** memory and compaction-related behaviors must be omitted, not weakly emulated
4. **Codex config merging is sensitive:** installer must avoid clobbering existing `~/.codex/config.toml`
5. **Hook support is feature-gated in Codex:** generated hook config may require best-effort activation rather than destructive config rewrites

---

## Requirements

### Functional Requirements

#### FR-1: Canonical Source Preservation

1. **FR-1.1**: `claude-pack/` MUST remain the only authored source for compatibility generation
2. **FR-1.2**: The Codex compatibility workflow MUST NOT require manual edits inside `claude-pack/`
3. **FR-1.3**: Generated Codex assets MUST be written outside `claude-pack/`
4. **FR-1.4**: The generation process MUST be deterministic from repository state plus explicit Codex override files

#### FR-2: Generated Output Layout

1. **FR-2.1**: The repository MUST contain a generated Codex output tree, such as `dist/codex/`
2. **FR-2.2**: Generated output MUST separate prompts, agents, hooks, rules, and skills into Codex-native locations
3. **FR-2.3**: Generated output MUST be safe to delete and rebuild
4. **FR-2.4**: Generated output MUST contain enough metadata to identify its source revision

#### FR-3: Command to Prompt Conversion

1. **FR-3.1**: Supported files in `claude-pack/commands/` MUST be converted into Codex prompt files
2. **FR-3.2**: Prompt names MUST be derived from Claude command filenames with the `_my_` prefix removed
3. **FR-3.3**: Prompt files MUST include Codex-compatible metadata such as name and description
4. **FR-3.4**: The generated prompt body MUST preserve the Claude command’s core workflow and instructions
5. **FR-3.5**: Generated prompts MUST be installable into Codex without manual editing

#### FR-4: Memory Feature Exclusion

1. **FR-4.1**: The Codex generation process MUST exclude `_my_capture`
2. **FR-4.2**: The Codex generation process MUST exclude `_my_memorize`
3. **FR-4.3**: The Codex generation process MUST exclude `_my_recall`
4. **FR-4.4**: The Codex generation process MUST exclude `_my_review_compact`
5. **FR-4.5**: Memory-dependent Claude agents, hooks, or helper assets MUST be excluded from Codex output
6. **FR-4.6**: Excluded items MUST be explicitly documented so absence is intentional and not mistaken for a broken install

#### FR-5: Agent Conversion

1. **FR-5.1**: Supported files in `claude-pack/agents/` MUST be converted into Codex custom agent definitions
2. **FR-5.2**: Generated agent files MUST include Codex-required fields: `name`, `description`, and `developer_instructions`
3. **FR-5.3**: Memory-dependent agents MUST be excluded
4. **FR-5.4**: Generated agent names MUST remain stable across rebuilds

#### FR-6: Rules Conversion

1. **FR-6.1**: Files in `claude-pack/rules/` MUST be consolidated into a generated Codex `AGENTS.md`
2. **FR-6.2**: The generated `AGENTS.md` MUST preserve the meaning of the source rules
3. **FR-6.3**: The generated document MUST clearly separate sections derived from different Claude rule files

#### FR-7: Skills Compatibility

1. **FR-7.1**: Existing Claude skill content that is structurally compatible MUST be converted into Codex `SKILL.md` directories
2. **FR-7.2**: The generation process MUST support Codex-only metadata or wrapper text without requiring edits to `claude-pack/skills/`
3. **FR-7.3**: Command-derived workflows MUST NOT be forced into Codex skills by default

#### FR-8: Hook Compatibility

1. **FR-8.1**: Existing reusable hook scripts MAY be installed for Codex where the lifecycle event still makes sense
2. **FR-8.2**: Memory-dependent hooks MUST be excluded
3. **FR-8.3**: The generated Codex layer MUST include a valid `hooks.json` when any supported hooks are present
4. **FR-8.4**: Hook installation MUST avoid overwriting unrelated user-defined hooks without warning

#### FR-9: Codex Installation Script

1. **FR-9.1**: The repository MUST provide a dedicated setup script for Codex installation
2. **FR-9.2**: The setup script MUST install generated assets into `~/.codex/`
3. **FR-9.3**: The setup script MUST create missing target directories as needed
4. **FR-9.4**: The setup script MUST be idempotent
5. **FR-9.5**: The setup script MUST preserve unrelated existing Codex assets
6. **FR-9.6**: The setup script MUST clearly report installed, skipped, and excluded assets

#### FR-10: Override Layer

1. **FR-10.1**: The repository MUST support a small Codex-specific override layer outside `claude-pack/`
2. **FR-10.2**: The override layer MUST handle cases where Codex requires additional metadata or different wording
3. **FR-10.3**: Overrides MUST be sparse and optional, not a second authored pack

### Non-Functional Requirements

1. The design SHOULD be implementable with repo-local scripts and no new heavy runtime dependencies
2. The generated compatibility layer SHOULD be easy to inspect in git
3. The install path SHOULD fail safely if Codex config merging is ambiguous
4. The solution SHOULD make future memory support additive rather than requiring a redesign

---

## Acceptance Criteria

### Core Functionality

- [ ] A developer can generate a Codex compatibility tree from the current `claude-pack/`
- [ ] A developer can install that generated tree into `~/.codex/` with one script
- [ ] Supported Claude commands appear in Codex as prompts rather than a hand-maintained parallel pack
- [ ] Supported Claude agents appear in Codex as custom agents
- [ ] Claude rule files appear in Codex as a generated `AGENTS.md`

### Exclusions and Safety

- [ ] Memory-related commands and agents are absent from the Codex install by design
- [ ] `claude-pack/` remains unchanged during generation and installation
- [ ] The setup flow does not overwrite unrelated existing user assets in `~/.codex/`

### Quality and Maintainability

- [ ] Generated output can be deleted and rebuilt without loss of authored content
- [ ] Codex-specific divergence is limited to a small override layer
- [ ] Generated output is traceable back to the source repository revision

---

## Related Artifacts

- **Research:** `.project/research/20260418-083015_codex-cli-compatibility-mapping.md`
- **Design:** `.project/active/codex-generated-compatibility/design.md`
- **Project Context:** `.project/CURRENT_WORK.md`

---

**Next Steps:** Implement the generator and installer, then validate the generated assets against a real `~/.codex/` installation.
