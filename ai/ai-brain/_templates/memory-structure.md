---
title: "Memory Structure: {{project_name}}"
type: memory-structure
project: {{project_name}}
generated_at: {{timestamp}}
generated_by: entrypoint-touch-write
---

# Memory Structure: {{project_name}}

## Canonical folders

- `projects/{{project_name}}/decisions/`
- `projects/{{project_name}}/constraints/`
- `projects/{{project_name}}/principles/`
- `projects/{{project_name}}/risks/`
- `projects/{{project_name}}/retrospections/`
- `projects/{{project_name}}/todos/`

## Node frontmatter minimum

- `title`
- `type`
- `project`
- `generated_at`
- `generated_by`
- `tags`

## Query discipline

- lookup-first by index and tags
- escalate to full-body only when needed
- use refs for large content
