# Troubleshooting

## The toolbar button is missing

Restart Studio after installing or updating the local plugin. Confirm only `PresetForge-v2.0.0.rbxm` is present in the local Plugins folder.

## Preview finds no targets

Check the selected containers, recipe class, required class filter, optional name text, and tag spelling. Descendants mode does not include the selected container itself.

## Apply is disabled

Run Preview first. Apply is available only when at least one compatible target has a pending change.

## Preview refreshes instead of applying

A target, value, selection, scope, or filter changed after Preview. Review the refreshed diff and apply again.

## A Project recipe will not load

Inspect `ServerStorage/PresetForgeProjectRecipes` for duplicate names, manual edits, or unsupported fields. PresetForge rejects malformed project data instead of guessing.

## I changed the wrong objects

Use one Studio Undo immediately. PresetForge records each Apply as one Change History operation.
