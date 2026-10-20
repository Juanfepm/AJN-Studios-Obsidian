from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import textwrap
from html import escape
import pymupdf

ROOT = Path(__file__).resolve().parents[1]
BASE = 'Graficos y Canvas/Idle Pirate'
IMAGES = ROOT / BASE / 'Graficos'
PATCHER = r'C:\Users\juanf\.obsidian-copilot\codex\2.2.2\codex-runtime\bin\codex.exe'
PROTECTED = [BASE + '/Graficos/00-vista-completa.png', BASE + '/Graficos/15-precios-referencia.png', BASE + '/Fuentes/Idle Pirate Game.pdf', 'Gamepasses y Precios/Gamepasses y precios.md', 'Gamepasses y Precios/Pet Crate - Probabilidades.md']
OBSOLETE = ['02-alpha-y-beta.png','03-monedas.png','04-trabajos-por-zona.png','05-sistema-de-trabajos.png','08-beneficios.png','09-taberna.png','10-recompensas.png','11-mercado.png','12-crew-y-rangos.png','13-dardos.png','14-ruleta.png']
GRAPHICS = [
    ('Equipo y patrocinio','01-equipo-y-patrocinio.png','Planificación'),
    ('Alpha, Beta y monedas','02-planificacion-y-monedas.png','Planificación'),
    ('Trabajos y ejecución · Reconstrucción legible','04-trabajos-y-ejecucion.svg','Trabajos'),
    ('Isla y propiedades','06-isla-y-propiedades.png','Isla'),
    ('Estructuras','07-estructuras.png','Isla'),
    ('Beneficios, taberna, recompensas y mercado','08-interacciones-de-la-isla.png','Isla'),
    ('Crew y rangos completos','12-crew-y-rangos-completos.png','Crew y minijuegos'),
    ('Sala de juegos, ruleta y probabilidades','13-minijuegos-y-probabilidades.png','Crew y minijuegos')
]

def patch_text(relative, content):
    path = ROOT / relative
    old = path.read_text(encoding='utf-8') if path.exists() else None
    if old == content:
        return
    if old is None:
        patch = '*** Begin Patch\n*** Add File: ' + relative + '\n' + ''.join('+' + l + '\n' for l in content.splitlines()) + '*** End Patch\n'
    else:
        patch = '*** Begin Patch\n*** Update File: ' + relative + '\n@@\n' + ''.join('-' + l + '\n' for l in old.splitlines()) + ''.join('+' + l + '\n' for l in content.splitlines()) + '*** End Patch\n'
    # Keep arguments below the Windows command-line limit.
    if len(patch) > 26000:
        raise ValueError('Patch too long: ' + relative)
    result = subprocess.run([PATCHER, '--codex-run-as-apply-patch', patch], cwd=ROOT, capture_output=True, text=True, encoding='utf-8')
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)

def composite(doc, filename, width, height, parts, scale=10):
    output = pymupdf.open()
    page = output.new_page(width=width, height=height)
    for source, target in parts:
        page.show_pdf_page(pymupdf.Rect(target), doc, 0, clip=pymupdf.Rect(source), keep_proportion=True)
    page.get_pixmap(matrix=pymupdf.Matrix(scale,scale), alpha=False).save(IMAGES / filename)
    output.close()

def jobs_svg():
    jobs = [
        ['Scrub the Deck','Unload Cargo','Deliver Messages'],
        ['Coil the Ropes','Stack Supplies','Run Market Errands'],
        ['Clean the Hull','Move Barrels','Help at the Tavern'],
        ['Patch the Sails','Repair the Docks','Gather Rumors'],
        ['Maintain the Cannons','Handle Shipments','Collect Debts'],
        ['Repair the Ship','Move Contraband','Track a Bounty'],
        ['Prepare for Voyage','Coordinate a Smuggling Run','Plan a Major Score'],
        ['Decipher the Cursed Char…','Raid the Royal Storehouse',"Infiltrate the Governor's Estate"],
        ['Master the Captain’s Wheel','Harbor Master Oversight','Operate the Black Market Syndicate']
    ]
    # Confirm every name against the detailed source page. The source cuts "Char".
    source = re.sub(r'\s+', ' ', SOURCE_DOC[2].get_text())
    for row in jobs:
        for name in row:
            assert name.rstrip('…') in source, name
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1260" viewBox="0 0 1600 1260">',
           '<title>Trabajos de Idle Pirate por zona y reglas de ejecución</title>',
           '<desc>Reconstrucción de los trabajos de la página 3 y las reglas de la página 1 del PDF; no reproduce los textos cortados del recorte original.</desc>',
           '<rect width="1600" height="1260" rx="24" fill="#f1f5f6"/>',
           '<g font-family="Segoe UI,Arial,sans-serif" fill="#20383f">']
    def text(x,y,content,size=24,weight=400,fill=None):
        svg.append(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}"' + (f' fill="{fill}"' if fill else '') + '>' + escape(content) + '</text>')
    text(44,65,'TRABAJOS POR ZONA',42,700)
    text(44,108,'27 trabajos · Nombres de la página 3 · Esquema reconstruido para facilitar la lectura',24)
    xs = [225,680,1135]
    for x,title in zip(xs,['SHIP · BARCO','PORT · PUERTO','TOWN · CIUDAD']):
        svg.append(f'<rect x="{x}" y="150" width="430" height="64" rx="12" fill="#203d47"/>')
        text(x+22,192,title,27,700,'#ffffff')
    labels = ['EASY']*3 + ['MEDIUM']*2 + ['HARD']*2 + ['SECRET','PREMIUM']
    fills = {'EASY':'#d9e9df','MEDIUM':'#eadac6','HARD':'#8f3d42','SECRET':'#73639d','PREMIUM':'#e7c579'}
    for i,(row,label) in enumerate(zip(jobs,labels)):
        y=235+i*72
        svg.append(f'<rect x="34" y="{y}" width="166" height="66" rx="10" fill="{fills[label]}"/>')
        text(48,y+41,label,23,700,'#ffffff' if label in ('HARD','SECRET') else '#20383f')
        for x,name in zip(xs,row):
            svg.append(f'<rect x="{x}" y="{y}" width="430" height="66" rx="10" fill="#ffffff"/>')
            lines=textwrap.wrap(name,width=31,break_long_words=False)
            for j,line in enumerate(lines):
                text(x+16,y+(39 if len(lines)==1 else 27)+j*27,line,23,500)
    svg.append('<rect x="34" y="925" width="1531" height="273" rx="18" fill="#ffffff"/>')
    text(58,971,'SISTEMA DE EJECUCIÓN',30,700)
    text(58,1019,'6 espacios desbloqueables.',25,600)
    text(58,1059,'Organiza y combina tus trabajos antes de comenzar.',24)
    text(58,1099,'Durante la ejecución no puedes añadir ni eliminar trabajos.',24)
    text(58,1155,'MP = Mastery Points',26,700)
    for i in range(6):
        x=1000+(i%3)*178
        y=988+(i//3)*78
        svg.append(f'<rect x="{x}" y="{y}" width="150" height="60" rx="12" fill="#dce9ed" stroke="#9bb7be"/>')
        text(x+62,y+40,str(i+1),30,700)
    text(999,1173,'Izquierda → derecha · arriba → abajo',20)
    text(44,1236,'Fuente: PDF, págs. 1 y 3. El nombre «Decipher the Cursed Char…» está cortado en la fuente.',21)
    svg.append('</g></svg>')
    return '\n'.join(svg) + '\n'

def update_canvas():
    relative = BASE + '/Tablero - Idle Pirate.canvas'
    canvas=json.loads((ROOT/relative).read_text(encoding='utf-8'))
    original_overview = next(n.copy() for n in canvas['nodes'] if n.get('file','').endswith('/00-vista-completa.png'))
    removed={'000000000000000d','000000000000000e','0000000000000011','0000000000000012','0000000000000019','000000000000001a','000000000000001b','000000000000001c','000000000000001d','000000000000001e','0000000000000023','0000000000000024'}
    canvas['nodes']=[n for n in canvas['nodes'] if n['id'] not in removed]
    canvas['edges']=[e for e in canvas.get('edges',[]) if e['fromNode'] not in removed and e['toNode'] not in removed]
    nodes={n['id']:n for n in canvas['nodes']}
    def change(suffix,**values):
        nodes[suffix.zfill(16)].update(values)
    def file(suffix,name,x,y,width,height):
        change(suffix,file=BASE+'/Graficos/'+name,x=x,y=y,width=width,height=height)
    change('b',text='**Alpha, Beta y monedas**',width=1020)
    file('c','02-planificacion-y-monedas.png',40,470,1020,295)
    change('6',text='# Trabajos\n\nEsquema legible reconstruido con las páginas 1 y 3 del PDF.')
    change('f',text='**Trabajos por zona y reglas de ejecución**',width=1020)
    file('10','04-trabajos-y-ejecucion.svg',1240,180,1020,803)
    change('17',text='**Beneficios e interacciones · Taberna, recompensas y mercado**',x=40,y=1970,width=2200)
    file('18','08-interacciones-de-la-isla.png',40,2010,2200,1076)
    change('4',height=1550)
    change('1f',text='**Crew y rangos · Recorte completo**',width=1020)
    file('20','12-crew-y-rangos-completos.png',2440,180,1020,554)
    change('21',text='**Sala de juegos, ruleta y probabilidades**',x=2440,y=780,width=1020)
    file('22','13-minijuegos-y-probabilidades.png',2440,840,1020,588)
    assert next(n for n in canvas['nodes'] if n.get('file','').endswith('/00-vista-completa.png')) == original_overview
    ids=[n['id'] for n in canvas['nodes']]
    assert len(ids)==len(set(ids)) and all(re.fullmatch('[0-9a-f]{16}',i) for i in ids)
    for n in canvas['nodes']:
        if n['type']=='file':
            assert (ROOT/n['file']).is_file(),n['file']
    # Verify card bounds, group padding and overlap (excluding container groups).
    groups=[n for n in canvas['nodes'] if n['type']=='group']
    cards=[n for n in canvas['nodes'] if n['type']!='group']
    for a in cards:
        assert any(a['x']>=g['x'] and a['y']>=g['y'] and a['x']+a['width']<=g['x']+g['width'] and a['y']+a['height']<=g['y']+g['height'] for g in groups) or a['id'] in ('0000000000000025','0000000000000026')
        for b in cards:
            if a['id']>=b['id']:
                continue
            assert not (a['x']<b['x']+b['width'] and b['x']<a['x']+a['width'] and a['y']<b['y']+b['height'] and b['y']<a['y']+a['height']), (a['id'],b['id'])
    patch_text(relative,json.dumps(canvas,ensure_ascii=False,separators=(',',':'))+'\n')

def update_notes():
    relative=BASE+'/Mesa de trabajo - Idle Pirate.md'
    existing=(ROOT/relative).read_text(encoding='utf-8')
    frontmatter='---'+existing.split('---',2)[1]+'---\n'
    body='# Mesa de trabajo · Idle Pirate\n\n'
    body+='**[[Graficos y Canvas/Idle Pirate/Tablero - Idle Pirate.canvas|Abrir tablero visual]]** · [[Gamepasses y precios|Precios]] · [[Pet Crate - Probabilidades|Mascotas]] · [[Pirate_Items_Table|Ítems]]\n\n'
    body+='> [!tip] Cómo recorrerlo\n> El tablero mantiene sus cuatro zonas: planificación, trabajos, isla y crew/minijuegos. Los gráficos relacionados están agrupados para reducir archivos y tarjetas. Amplía cada tarjeta para consultar sus detalles.\n\n'
    body+='![[Graficos y Canvas/Idle Pirate/Graficos/00-vista-completa.png|1000]]\n\n'
    for group in ['Planificación','Trabajos','Isla','Crew y minijuegos']:
        body+='> [!example]- '+group+'\n'
        for title,name,g in GRAPHICS:
            if g==group:
                body+='> **'+title+'**\n> ![['+BASE+'/Graficos/'+name+'|1000]]\n>\n'
        body+='\n'
    body+='> [!info]- Corrección del gráfico de trabajos\n> El recorte de la página 1 ya contiene letras cortadas y guiones en el PDF. Se sustituyó por un esquema vectorial legible: los 27 nombres proceden de la página 3 y las reglas de ejecución, los seis espacios y Mastery Points, de la página 1. No es una recuperación literal del recorte ilegible.\n>\n> «Decipher the Cursed Char…» conserva la indicación de nombre cortado en la fuente. Para la progresión de niveles y las cifras de balance, consulta [[Tabla_Niveles_y_Trabajos]]. El esquema no mezcla duraciones de fuentes que pueden diferir.\n\n'
    body+='> [!info]- Fuente y alcance\n> Fuente: [[Graficos y Canvas/Idle Pirate/Fuentes/Idle Pirate Game.pdf#page=1|PDF, página 1]] y [[Graficos y Canvas/Idle Pirate/Fuentes/Idle Pirate Game.pdf#page=3|página 3 para trabajos]].\n>\n> Se conservan la vista completa y ocho gráficos temáticos. Los recortes de interacciones, crew y minijuegos reúnen las partes relacionadas sin cortar los textos. Las imágenes incrustadas independientes se retiraron: los gráficos conservados son archivos autónomos y el PDF sigue disponible.\n>\n> Las tablas de [[Gamepasses y precios]] y [[Pet Crate - Probabilidades]] conservan su contenido.\n'
    patch_text(relative,frontmatter+'\n'+body)
    relative='Tablas y Datos/Índice de tablas - Idle Pirate Game.md'
    text=(ROOT/relative).read_text(encoding='utf-8')
    text=text.replace('Tablero visual, 14 gráficos y recursos de la página 1','Tablero visual, 8 gráficos agrupados y trabajos reconstruidos')
    patch_text(relative,text)
    relative='outputs/extraer_canva.py'
    wrapper='"""Regenera solo los gráficos depurados; conserva las vistas generales y gamepasses."""\nfrom depurar_graficos import main\n\nif __name__ == "__main__":\n    main()\n'
    patch_text(relative,wrapper)

def main():
    global SOURCE_DOC
    before={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in PROTECTED}
    SOURCE_DOC=pymupdf.open(ROOT/BASE/'Fuentes'/'Idle Pirate Game.pdf')
    svg=jobs_svg()
    patch_text(BASE+'/Graficos/04-trabajos-y-ejecucion.svg',svg)
    composite(SOURCE_DOC,'02-planificacion-y-monedas.png',166,48,[([59,80,225,128],[0,0,166,48])],10)
    composite(SOURCE_DOC,'08-interacciones-de-la-isla.png',180,88,[
        ([345,260,408,275],[59,3,122,18]),
        ([326,278,385,326],[3,25,62,73]),
        ([391,278,434,325],[69,25,112,72]),
        ([443,278,481,330],[126,25,164,77])],10)
    composite(SOURCE_DOC,'12-crew-y-rangos-completos.png',140,76,[
        ([474,192,533,247],[5,10,64,65]),
        ([497,250,558,310],[73,10,134,70])],12)
    composite(SOURCE_DOC,'13-minijuegos-y-probabilidades.png',137,79,[([306,326,443,405],[0,0,137,79])],12)
    update_canvas()
    update_notes()
    after={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in PROTECTED}
    assert before==after,'Protected files changed'
    manifest={'source':BASE+'/Fuentes/Idle Pirate Game.pdf','thematic_graphics':[n for _,n,_ in GRAPHICS],'obsolete_graphics':OBSOLETE,'protected_sha256':before,'original_resources':'Removed after reference verification; retained graphics are standalone.','jobs_reconstruction_sources':{'job_names':3,'execution_rules':1}}
    patch_text('outputs/canva/extraccion.json',json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'thematic_graphics':len(GRAPHICS),'protected_files_unchanged':True,'obsolete_files_ready_for_removal':OBSOLETE},ensure_ascii=False))

if __name__=='__main__':
    main()
