# Markdown Authoring

**One line per paragraph. Never hard-wrap prose.**

When you write or edit any `.md` file — every `.project` artifact (specs, designs, plans, research, handoffs, status notes) and every other markdown file — keep each paragraph, bullet, and heading on a single source line. Do not insert line breaks to wrap text at 80, 90, or any other column width.

A newline in the middle of a markdown paragraph renders as a space anyway. Hard-wrapping buys nothing and costs plenty: it makes the source ugly, makes diffs noisy (one reworded sentence re-wraps the whole paragraph), and makes editing a chore. Let the editor soft-wrap on screen.

- Each paragraph: one line.
- Each list item: one line. (Only break if the item genuinely contains multiple paragraphs.)
- Use blank lines only where markdown needs them structurally — between paragraphs, around headings, around lists and code blocks. Not as decorative padding.
