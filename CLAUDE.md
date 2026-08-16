# CLAUDE.md

## Overview

Per-PR preview environments for a full-stack Next.js app — RSC and Server Actions backed by a database. The preview environment itself is not implemented yet; the repository currently holds the Next.js app and its database layer.

## Docs

- `README.md` — Project overview and usage
- `CONTRIBUTING.md` — Developer guide: commands and workflow
- `docs/DESIGN.md` — Design and architecture

## Skills

## MCP

## Updating dependencies

After changing dependencies, run `nix flake check` and copy the correct hash from the `got:` line in the error output into `nix/node-modules.nix`.
