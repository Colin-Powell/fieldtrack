# 📊 Documentation Images

This folder is reserved for diagrams and screenshots referenced by the FieldTrack documentation.

## Recommended Images

| File | Used in | Description |
|------|---------|-------------|
| `architecture.png` | [02_System_Architecture.md](../02_System_Architecture.md) | High-level architecture diagram |
| `database-erd.png` | [03_Database_Design.md](../03_Database_Design.md) | Database ER diagram |
| `student-flow.png` | [06_Student_Portal.md](../06_Student_Portal.md) | Student workflow diagram |
| `supervisor-flow.png` | [07_Supervisor_Portal.md](../07_Supervisor_Portal.md) | Supervisor workflow diagram |
| `admin-flow.png` | [08_Admin_Portal.md](../08_Admin_Portal.md) | Admin workflow diagram |
| `student-portal.png` | [06_Student_Portal.md](../06_Student_Portal.md) | Student portal screenshot |
| `supervisor-portal.png` | [07_Supervisor_Portal.md](../07_Supervisor_Portal.md) | Supervisor portal screenshot |
| `admin-portal.png` | [08_Admin_Portal.md](../08_Admin_Portal.md) | Admin portal screenshot |

## Notes

- The Markdown documents use **Mermaid.js** diagrams, which render natively on GitHub.
- When embedding exported diagrams or app screenshots, use relative paths:

  ```markdown
  ![Architecture](./images/architecture.png)
  ```

- Keep screenshots up to date with each UI release.

