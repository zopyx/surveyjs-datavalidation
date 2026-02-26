# surveyjs_data_validation

Validate SurveyJS form data against a SurveyJS schema from the command line.

This repository includes:

- `validate.mjs`: Node/Bun CLI that runs validation with `survey-core`
- `validate_data.py`: Python wrapper that runs a native binary (`validate-linux` / `validate-mac`)
- `deno_build.py`: Builds native binaries from `validate.mjs` using Deno
- `Makefile`: Build helpers for Bun and Deno targets
- Sample files: `survey.json`, `data-valid.json`, `data-invalid.json`

## What It Produces

The validator writes a JSON result file like:

```json
{
  "valid": true,
  "errors": []
}
```

On validation failure, it exits with code `1` and writes per-question errors to the result JSON.

## Quick Start (Node/Bun)

Install JS dependencies:

```bash
bun install
```

Run validation directly:

```bash
node validate.mjs --schema-json survey.json --form-json data-valid.json --result-json output.json
```

Or with Bun:

```bash
bun validate.mjs --schema-json survey.json --form-json data-valid.json --result-json output.json
```

Print the bundled `survey-core` version:

```bash
node validate.mjs --version
```

Test invalid input:

```bash
node validate.mjs --schema-json survey.json --form-json data-invalid.json --result-json output.json
```

## Python Wrapper

Run the Python wrapper:

```bash
python validate_data.py --schema-json survey.json --form-json data-valid.json --result-json output.json
```

Behavior:

- Uses `validate-linux` on Linux and `validate-mac` on macOS
- If the binary is missing (or stale in some build paths), it can build via `deno_build.py`
- Returns the same exit code as the native validator

## Building Native Binaries

### Bun builds (output in `dist/`)

```bash
make install
make mac
make linux
```

This produces:

- `dist/survey-validate-macos`
- `dist/survey-validate-linux`

### Deno builds (root binaries used by Python wrapper)

```bash
python deno_build.py --targets current
```

Or build both targets:

```bash
python deno_build.py --targets darwin linux
```

This produces binaries in the project root:

- `validate-mac`
- `validate-linux`

## Tests

Run unit tests:

```bash
python -m unittest discover -s tests
```

## CLI Options

Both `validate.mjs` and `validate_data.py` support:

- `-s`, `--schema-json <path>`
- `-f`, `--form-json <path>`
- `-r`, `--result-json <path>`

`validate.mjs` also supports:

- `--version`

## Notes

- Relative input paths are resolved from the current working directory, the executable directory, or the module directory.
- Output paths are written relative to the current working directory unless an absolute path is provided.
