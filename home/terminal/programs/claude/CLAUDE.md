# Systematic Problem-Solving Framework

A conversation between User and Assistant. The user asks a complex question, and the Assistant solves it systematically.

The Assistant **must**:
1. Break down the problem into smaller sub-problems.
2. **Generate and evaluate multiple approaches** (Tree of Thoughts).
3. Explicitly state assumptions or uncertainties.
4. Use domain-specific reasoning for the chosen approach.
5. Verify intermediate steps and final answer.

**Strict Format**:
<think>

[Step 1: Problem Decomposition]
- Identify key components and possible strategies.
- Use "Wait." to pause and consider additional aspects.
- For significant realizations, use multiple "Wait" statements (e.g., "Wait, wait. Wait.")
- Example: "Wait. To solve X, I could use Method A, B, or C."

[Step 2: Generate & Compare Approaches]
- Approach 1: [Idea + pros/cons]
- Approach 2: [Idea + pros/cons]
- Approach 3: [Idea + pros/cons]
- Use "Wait." to reconsider or analyze further.
- Example: "Wait. Approach 1 is simple but slow; Wait. Approach 2 is faster but uses more space."
- For breakthrough insights: "Wait, wait. Wait. That's an important realization..."

[Step 3: Select Best Approach]
- Use "Wait." to double-check selection criteria.
- Example: "Wait. Choose Approach 2 due to O(n²) time complexity."
- When discovering a better approach: "Wait, wait. Wait. Let's reevaluate our choice..."

[Step 4: Assumptions/Uncertainties]
- Use "Wait." to identify potential issues.
- Example: "Wait. Assuming input is sorted; if not, pre-sort it."
- For critical assumptions: "Wait, wait. Wait. We need to verify this key assumption..."

[Step 5: Domain-Specific Execution]
- Use "Wait." to verify each step.
- Example: "Wait. Implement Approach 2 with edge-case handling."
- For potential mistakes: "Wait, wait. Wait. Let's step back and recheck our work..."

[Step 6: Validation]
- Use "Wait." to thoroughly check results.
- Example: "Wait. Test with input size 10⁴ to confirm O(n²) runtime."
- For unexpected results: "Wait, wait. Wait. This outcome requires deeper analysis..."

[Step 7: Uncertainty Resolution]
- Use "Wait." to address any remaining concerns.
- For major revisions: "Wait, wait. Wait. We need to fundamentally rethink this..."

Note: Multiple "Wait" statements (e.g., "Wait, wait. Wait.") indicate an "aha moment" or critical realization that requires special attention and reevaluation of the current approach. 
These moments often lead to breakthrough insights or important corrections in the reasoning process.
</think>

<answer>
Final answer after validation
</answer>

## Development Best Practices

- Always consider security implications of file access and command execution
- Validate inputs and handle edge cases
- Write clear, maintainable code with appropriate comments
- Test thoroughly before suggesting changes
- Consider performance implications of proposed solutions
- Follow language-specific conventions and style guides

## Nix Development Environment

This project uses **NixOS** and the **Nix package manager** for declarative system configuration and reproducible development environments.

### Critical Requirements

1. **All development commands must run in a Nix environment**
   - Development tools, compilers, and dependencies are managed through `flake.nix`
   - Do NOT assume system-wide installation of tools (npm, cargo, python, etc.)
   - Always verify tool availability through Nix before executing commands

2. **Running commands in Nix environment**
   - Use `nix develop` to enter a development shell with all dependencies
   - Use `nix develop --command <cmd>` to run a single command with Nix environment
   - Use `nix-shell` as an alternative to enter the development environment
   - Check `flake.nix` to understand available development shells and dependencies

3. **Building and testing**
   - Use `nix build` to build Nix packages and configurations
   - Use `nix build .#<output>` to build specific outputs defined in flake.nix
   - Test configuration changes with `nixos-rebuild test` (requires root)
   - Apply system configuration with `nixos-rebuild switch` (requires root)

4. **Package management**
   - System packages are declared in Nix configuration files (not installed imperatively)
   - User packages are managed through home-manager in the `home/` directory
   - To add a new tool: modify the appropriate `.nix` file, don't use `apt`, `npm install -g`, etc.

5. **Configuration structure**
   - `/system/` - System-level NixOS configuration
   - `/home/` - User-level home-manager configuration
   - `/hosts/` - Host-specific configurations
   - `flake.nix` - Main entry point defining all outputs and dependencies
   - `flake.lock` - Locked dependency versions (don't modify directly)

### When suggesting changes

- **Before executing any build/dev command**: Verify it's available in the Nix environment
- **Before suggesting package installation**: Identify the correct Nix configuration file to modify
- **When adding new tools**: Suggest adding them to the appropriate Nix configuration, not installing them imperatively
- **For testing changes**: Suggest using `nix build` or `nixos-rebuild test` rather than system-wide changes
- **For dependencies**: Check if they need to be added to `flake.nix` or specific package configurations

### Example workflows

**Running a development command:**
