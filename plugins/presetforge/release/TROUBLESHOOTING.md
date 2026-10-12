# Troubleshooting

## The toolbar button is missing

Restart Studio after installing or updating the local plugin. Keep only one PresetForge installation; the current local package is `PresetForge-v2.1.0.rbxm`.

## Preview finds no targets

Check the selected containers, recipe class, required class filter, optional name text, and tag spelling. Descendants mode does not include the selected container itself.

## Apply is disabled

Run Preview first. Apply is available only when at least one compatible target has a pending change.

## Preview refreshes instead of applying

A target, selected value, selection, scope, or filter changed after Preview. Run Preview again and review before applying. Changes to unselected properties do not invalidate it.

## Frame cannot locate an object

Non-spatial objects may have no 3D bounds. Use Select to locate the exact result in Explorer. Results with identical names are separate selectable rows.

## Edit refuses my duplicated recipe

Select exactly one source of the recipe's class. Duplicate copies the stored recipe; Edit captures values from the selected source, not from typed arbitrary properties.

## A Project recipe will not load

Inspect `ServerStorage/PresetForgeProjectRecipes` for duplicate names, manual edits, or unsupported fields. PresetForge rejects malformed project data instead of guessing.

## I changed the wrong objects

Use one Studio Undo immediately. PresetForge records each Apply as one Change History operation.
