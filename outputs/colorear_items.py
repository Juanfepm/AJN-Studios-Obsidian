from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PATCHER = r'C:\Users\juanf\.obsidian-copilot\codex\2.2.2\codex-runtime\bin\codex.exe'
PALETTE = {"Common":"#d9d9d9","Uncommon":"#c4d9a8","Rare":"#a9dcf0","Epic":"#a08cc8","Legendary":"#ddbb80","Mythic":"#e8649e","Treasure":"#ffc65a","Cursed":"#1e1e1e","Blessed":"#ffffff","Events and Proud":"#5b5bc8","XMAS":"#f4dada"}

def badge(name):
    foreground = '#ffffff' if name in ('Cursed', 'Events and Proud') else '#171717'
    return f'<span style="background-color:{PALETTE[name]};color:{foreground};padding:2px 6px;border:1px solid #888888;border-radius:4px">{name}</span>'

def patch_file(path, changes):
    patch = '*** Begin Patch\n*** Update File: ' + path + '\n'
    for old, new in changes:
        patch += '@@\n' + ''.join('-' + x + '\n' for x in old.splitlines()) + ''.join('+' + x + '\n' for x in new.splitlines())
    patch += '*** End Patch\n'
    result = subprocess.run([PATCHER, '--codex-run-as-apply-patch', patch], capture_output=True, text=True, encoding='utf-8', cwd=ROOT)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)

def main():
    path = 'Tablas y Datos/Pirate_Items_Table.md'
    text = (ROOT / path).read_text(encoding='utf-8')
    changes = []
    count = 0
    for line in text.splitlines():
        if not line.startswith('|'):
            continue
        cells = line.split('|')
        changed = False
        for i in range(1, len(cells)-1):
            name = next((n for n in PALETTE if n.lower() == cells[i].strip().lower()), None)
            if name:
                cells[i] = ' ' + badge(name) + ' '
                changed = True
                count += 1
        if changed:
            changes.append((line, '|'.join(cells)))
    for start in range(0, len(changes), 8):
        patch_file(path, changes[start:start+8])
    if '## Guía de calidad' not in text:
        legend = '## Guía de calidad\n\nColores comprobados en la hoja original de Google Sheets (Overview, A3:A13). Cada etiqueta conserva su nombre para no depender solo del color.\n\n' + ' · '.join(badge(n) for n in PALETTE) + '\n\n[[Mesa de trabajo - Idle Pirate|Tablero de diseño]] · [[Gamepasses y precios|Gamepasses y precios]]\n\n## Overview'
        patch_file(path, [('## Overview', legend)])
    print(json.dumps({'rarity_cells_colored':count,'items':265},ensure_ascii=False))

if __name__ == '__main__':
    main()
