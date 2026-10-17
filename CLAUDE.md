# Ganimedes 2.0 - Core Guidelines

## Commands

- Backend compile check: python3 -m py\_compile agente-ia/app/\*\*/\*.py

- Rust compile check: cargo check --manifest-path panelpc/Cargo.toml

- Flutter analyze: flutter --directory ganimedes analyze

## Architecture

- Backend: PocketBase (Multi-tenant filtered by business\_name)

- Agent-IA: FastAPI (:8000) eager context loading

- Frontend: Flutter mobile POS &amp; Rust desktop panel

## Rules (Strict)

- Never query PocketBase without business\_name filter.

- Do not perform broad directory search; read only current\_[task.md](http://task.md).