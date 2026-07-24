# Skills with Executable Code

Rules for Skills that bundle executable scripts alongside their instructions.

## Contents

- Solve, Don't Punt
- Provide Utility Scripts
- Use Visual Analysis
- Create Verifiable Intermediate Outputs
- Package Dependencies
- Runtime Environment

## Solve, Don't Punt

When writing scripts for Skills, handle error conditions rather than punting to Claude.

**Good example: Handle errors explicitly**:

```python
def process_file(path):
    """Process a file, creating it if it doesn't exist."""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        # Create file with default content instead of failing
        print(f"File {path} not found, creating default")
        with open(path, "w") as f:
            f.write("")
        return ""
    except PermissionError:
        # Provide alternative instead of failing
        print(f"Cannot access {path}, using default")
        return ""
```

**Bad example: Punt to Claude**:

```python
def process_file(path):
    # Just fail and let Claude figure it out
    return open(path).read()
```

Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it?

**Good example: Self-documenting**:

```python
# HTTP requests typically complete within 30 seconds
# Longer timeout accounts for slow connections
REQUEST_TIMEOUT = 30

# Three retries balances reliability vs speed
# Most intermittent failures resolve by the second retry
MAX_RETRIES = 3
```

**Bad example: Magic numbers**:

```python
TIMEOUT = 47  # Why 47?
RETRIES = 5  # Why 5?
```

## Provide Utility Scripts

Pre-made scripts are more reliable than generated code, save tokens (no need to include code in context), and ensure consistency. Claude can execute them without loading their contents into context.

Make clear whether Claude should **execute** the script (most common: "Run `analyze.py` to extract fields") or **read it as reference** for complex logic. Prefer execution.

Document each script with its invocation line and, when the script emits structured data another step consumes, the shape of its output. Without the output shape, the consuming step has to run the script just to discover what it produces.

## Use Visual Analysis

When inputs can be rendered as images, have Claude analyze them: convert the input to images with a bundled script, then read the images to identify structure and layout. Claude's vision capabilities help understand layouts and structures that are awkward to extract programmatically.

## Create Verifiable Intermediate Outputs

For batch operations, destructive changes, or high-stakes work, use the **plan-validate-execute** pattern: Claude first creates a plan in a structured format (e.g., `changes.json`), a script validates the plan against reality, and only then is the plan executed. The workflow becomes: analyze → create plan file → validate plan → execute → verify.

This catches errors before any changes are applied, and lets Claude iterate on the plan without touching originals. Make validation errors specific ("Field 'signature_date' not found. Available fields: customer_name, order_total") so Claude can fix issues without guessing.

## Package Dependencies

Don't assume packages are available. Declare them explicitly with install commands: give the install line first, then the usage.

- ✗ **Avoid**: "Use the <library> library to process the file."
- ✓ **Good**: "Install required package: `<install command>`" followed by the usage snippet.

Skills run in the code execution environment with platform-specific limitations:

- **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
- **Claude API**: Has no network access and no runtime package installation

List required packages in your SKILL.md and verify they're available in your execution environment.

## Runtime Environment

- **Scripts produce output, not context**: Utility scripts can be executed via bash without loading their contents into context. Only the script's output consumes tokens.
- **Name files descriptively**: Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
- **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets; no context penalty until accessed
- **Test file access patterns**: Verify Claude can navigate your directory structure by testing with real requests
