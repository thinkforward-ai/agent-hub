---
name: install-integration
description: Discover or install integrations, configure optional shell aliases, guide the user until the integration works, and map project capabilities.
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
   process. When privileged installation is needed and `sudo` cannot prompt,
   use `pkexec` in a local active graphical session so the user approves in
   the desktop password dialog; otherwise give the user the command to run.
   Keep OS-managed tools in their normal locations. Install custom
   resources under `${AGENT_HUB_HOME:-$HOME/.agent-hub}/tools/<id>/`,
   preserving relative paths. Do not create redundant bin links or wrappers.
   Implementation languages are unrestricted. Preserve existing files;
   stop on unmanaged collisions and retain prior managed content for recovery.
   Do not introduce `.local`/`.config` storage or edit shell startup files;
   Agent Hub's installer owns the marked `~/.bashrc` bootstrap hook.

7. Deploy this skill's declared bootstrap resource as `bootstrap.sh` in
   Agent Hub home when it is missing or outdated. Preserve unrelated content and disclose
   updates in the installation plan.

8. Optional `metadata.integration.aliases` declares shell alias names and
   default argument arrays. Store selected bindings in Hub's `aliases.sh`.
   Bind unclaimed names; preserve existing selections when another provider
   is installed. Do not silently shadow unmanaged names. Quote executable
   paths and default arguments safely; never evaluate metadata as shell code.
   No declared aliases means no alias configuration.

9. New interactive Bash shells load Hub bootstrap through the installer's
   `~/.bashrc` hook; explain opening a new terminal, or sourcing it in the
   current shell, scripts, or shells without the hook.
   Aliases are not inherited by child processes. Noninteractive Bash requires
   alias expansion, and alias definitions must be loaded before the command
   using them is parsed.

10. Guide the user until the integration is fully installed and works.
    Give one remaining user-run step at a time, such as privileged dependency
    installation, activation, or verification, with its expected result, and
    wait for the outcome. Do not automatically run the installed tool, its
    aliases, smoke tests, or self-tests. On failure, diagnose with read-only
    inspection and propose the next step; changes beyond the approved plan
    need a new preview and approval. Finish when the user confirms it works;
    if they stop earlier, report readiness as unverified.

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
