---
name: reorder-supplementary
description: "Use when a manuscript has supplementary figures and tables that need to be reordered so their numbering matches the order in which they are first cited in the main manuscript. Ideal for journal submissions, revisions, and appendix cleanup where cross-references and numbering must stay consistent."
---

# Reorder supplementary material

Use this skill when the main manuscript cites supplementary items in one sequence, but the appendix or supplementary files are arranged alphabetically, by file name, or by creation order instead. The goal is to make the supplementary material follow the same order as the first citation in the main manuscript.

## Core rule

The source of truth is the first citation in the manuscript text, not the file name, table number, or the order in which figures were generated.

## Workflow

1. Read the main manuscript and extract every in-text reference to supplementary figures and tables.
   - Look for patterns such as Figure S1, Figure S2, Table S1, Table S2, and any caption references.
   - Record the first time each supplementary item is cited.
   - If an item is mentioned in the abstract, results, methods, or discussion, treat that as the citation order anchor.

2. Build a citation-order list.
   - Sort all supplementary items by the first manuscript citation.
   - Keep figure and table references distinct while preserving their first appearance in the text.
   - If a table and figure are cited in alternating order, follow that interleaved sequence.

3. Inspect the supplementary files or appendix content.
   - Confirm each current label matches the actual object.
   - Identify duplicate, missing, or out-of-sequence labels.
   - Check for tables and figures that are not cited anywhere in the manuscript and decide whether they should be dropped, renumbered, or retained as unreferenced material.

4. Renumber the supplementary material to match the citation order.
   - Assign the new supplementary numbers based on the first-citation sequence.
   - Preserve the distinction between figures and tables, but do not reorder by type if the manuscript cites them in mixed order.
   - Update figure/table captions, labels, and internal references to reflect the new numbering.

5. Update all manuscript references.
   - Replace old labels in the main text, captions, and cross-references.
   - Verify that any label used in the body, methods, or appendix now matches the new numbering.
   - Ensure that every supplementary item is referenced consistently and no stale numbers remain.

6. Run a validation pass.
   - Check that every supplementary figure and table appears once in the manuscript citation order.
   - Ensure no numbers are skipped, duplicated, or left orphaned.
   - Confirm the supplementary appendix now matches the manuscript’s first-citation sequence exactly.

## Decision points

- If the manuscript cites only tables or only figures, reorder within that type by first citation and keep other items out of the sequence.
- If the manuscript cites figures and tables in mixed order, preserve the mixed order rather than grouping all figures first and all tables later.
- If a supplementary item is never cited, keep it only if it is explicitly required by the journal and make its status clear; otherwise remove or renumber it to avoid orphaned material.
- If numbering is already correct but the appendix layout is not, reorder the visible appendix entries to match the manuscript sequence without changing the scientific content.
- If a revision changes the citation order, rebuild the citation-order list from the revised manuscript rather than reusing the old numbering.

## Quality criteria

A successful reorder has all of the following:

- Every supplementary figure and table appears in the same order as the first time it is cited in the main manuscript.
- No duplicated, skipped, or stale labels remain.
- Figure captions, table captions, and in-text references are all synchronized.
- The appendix is visually ordered the same way the manuscript first introduces each item.
- The final supplementary sequence is internally consistent and journal-ready.

## Output expected

Return one of these two outcomes:

1. A clean reordered supplementary sequence with the new numbering and all cross-references updated.
2. A short list of unresolved citations or conflicting labels that need human review before finalizing.

## Example prompt

"Reorder the supplementary figures and tables so that they appear in the same order as they are first cited in the main manuscript. Update the captions and any in-text references to match the new numbering, and flag any uncited or duplicate supplementary items."

## Related tasks

- Renumbering supplementary figures and tables after manuscript revision
- Aligning appendix ordering with the main manuscript narrative
- Cleaning up cross-references before journal submission
- Preparing a manuscript for Nature-family or journal appendix review