# next-prenv

## Overview

Per-PR preview environments for a Next.js app.

## Features

- Preview environment per pull request

## Prerequisites

## Usage

- `preview` label on a PR → preview URL commented on the PR
- PR close (or manual run) → destroyed
- idle 3+ days → destroyed by the daily GC

## Directory Structure

```
.
├── prisma/                 Database schema and migrations
├── src/app/                Next.js App Router
├── terraform/env/dev/      Persistent config
├── terraform/env/preview/  Temporary per-PR config
└── .github/workflows/      Deploy and teardown automation
```
