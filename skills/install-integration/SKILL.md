---
name: install-integration
description: Discover or install integrations, configure optional shell aliases, provide user-run verification steps, and map project capabilities.
source: https://github.com/thinkforward-ai/agent-hub
metadata:
  resources:
    - scripts/bootstrap.sh
---

# Install an Integration

1. Read the tool skill's `metadata.integration` and additional instructions.
   Require dependency and resource arrays; use `[]` when empty. All source
   resources belong in metadata. For native tooling, `command` names an OS
   executable. For bundled tooling, it identifies an executable resource
   relative to the resource root.

2. For discovery, inspect metadata, command locations, and files without
   invoking integration commands. Report detected installation separately
   from user-confirmed readiness. Do not install, download, authenticate,
   activate shell configuration, or change preferences during discovery.
   Do not maintain a separate installed-tool inventory.

3. Before installation changes, describe the complete plan: dependencies
   to reuse or install, sources, commands, privileges, affected files,
   alias selections, project mappings, activation, user-run verification,
   and rollback limits. Use only trusted read-only inspection beforehand.

4. Highlight any major or critical security risks, including their cause,
   possible impact, and available mitigation. Disclose material uncertainties.
   If none are identified, say so without claiming the installation is
   risk-free.

5. After the preview and risk disclosure, ask with exactly two options:
   `Allow` and `Reject`. Proceed only after explicit `Allow`. Rejection,
   cancellation, or no answer means no installation changes. Material
   changes to the plan or risks require another preview and approval.

6. Reuse suitable native dependencies or follow the approved OS installation
   process. Keep OS-managed tools in their normal locations. Install custom
   resources under `${AGENT_HUB_HOME:-$HOME/.agent-hub}/tools/<id>/`,
   preserving relative paths. Do not create redundant bin links or wrappers.
   Implementation languages are unrestricted. Preserve existing files;
   stop on unmanaged collisions and retain prior managed content for recovery.
   Do not introduce `.local`/`.config` storage or edit shell startup files.

7. Deploy this skill's declared bootstrap resource as `bootstrap.sh` in
   Agent Hub home when needed. Preserve unrelated content and disclose
   updates in the installation plan.

8. Optional `metadata.integration.aliases` declares shell alias names and
   default argument arrays. Store selected bindings in Hub's `aliases.sh`.
   Bind unclaimed names; preserve existing selections when another provider
   is installed. Do not silently shadow unmanaged names. Quote executable
   paths and default arguments safely; never evaluate metadata as shell code.
   No declared aliases means no alias configuration.

9. Explain how to source Hub bootstrap in the shell that will invoke an alias.
   Aliases are not inherited by child processes. Noninteractive Bash requires
   alias expansion, and alias definitions must be loaded before the command
   using them is parsed.

10. Leave verification to the user. Provide manual steps and expected results.
    Do not automatically run the installed tool, its aliases, smoke tests,
    or self-tests. Report functional readiness as unverified until the user
    confirms it.

11. When project mapping is requested, identify the project, capability,
    chosen integrations, and purpose. Ask only for missing information.
    Record the approved mapping in the project's `capabilities.md`.
    Preserve unrelated mappings and omit machine-specific installation state.
    Capability mapping does not automatically create an alias.

12. On failure, restore prior managed content where safe and report changes
    that cannot safely be reversed. Do not automatically uninstall OS packages.
    Report installation status, alias selections, activation instructions,
    project mappings, and user verification steps. Installation permission
    does not authorize later tool execution.
