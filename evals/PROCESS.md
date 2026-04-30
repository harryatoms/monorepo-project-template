# Eval Process

The boilerplate includes a small optional eval scaffold for projects that want to keep prompts, datasets, and baselines versioned with the code.

The default `example` eval is deterministic and does not call an external LLM. It verifies that the optional prompt package and bundled dataset can be loaded and that the result format works with the comparison script.

## Run Evals

```bash
make eval CALL=example
make eval-compare CALL=example
make eval-gate
```

The root Makefile uses `apps/example-api/.venv/bin/python` by default. Run `make bootstrap APP=example-api` first if the environment does not exist.

## Customize For A Project

1. Add prompt templates and call configs in `packages/example-prompts`.
2. Add datasets and loaders in `packages/example-evals`.
3. Update `evals/scripts/run.py` with project-specific scoring logic.
4. Regenerate the committed baseline in `evals/baselines`.
5. Enable or tune CI eval gates once the project has real AI behavior to protect.

External provider evals should read credentials from environment variables or SSM paths and stay optional by default.
