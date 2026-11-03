import os, sys, shutil, re
import xml.etree.ElementTree as ET

SRC = sys.argv[1]
OUT = sys.argv[2]
NAMES = sys.argv[3:]


def strip(tag):
    return tag.split('}')[-1]


def find_all(el, name):
    return [c for c in el.iter() if strip(c.tag) == name]


def child(el, name):
    for c in el:
        if strip(c.tag) == name:
            return c
    return None


def convert(dae_path, out_dir, name):
    tree = ET.parse(dae_path)
    root = tree.getroot()
    base = os.path.dirname(dae_path)
    up = 'Z'
    for e in find_all(root, 'up_axis'):
        up = (e.text or 'Z_UP').strip()[0]
    scale = 1.0
    for e in find_all(root, 'unit'):
        scale = float(e.get('meter', '1'))
    images = {}
    for img in find_all(root, 'image'):
        ref = child(img, 'init_from')
        if ref is not None and ref.text:
            images[img.get('id')] = ref.text.strip()
    effects = {}
    for eff in find_all(root, 'effect'):
        tex = None
        for ps in find_all(eff, 'newparam'):
            s = child(ps, 'surface')
            if s is not None:
                f = child(s, 'init_from')
                if f is not None and f.text:
                    tex = f.text.strip()
                    break
        effects[eff.get('id')] = tex
    materials = {}
    for m in find_all(root, 'material'):
        ie = child(m, 'instance_effect')
        if ie is not None:
            materials[m.get('id')] = ie.get('url', '').lstrip('#')
    # símbolo do triângulo -> imagem (via instance_material nas cenas)
    symbol_to_mat = {}
    for im in find_all(root, 'instance_material'):
        symbol_to_mat[im.get('symbol')] = im.get('target', '').lstrip('#')

    os.makedirs(out_dir, exist_ok=True)
    obj_lines = []
    mtl = {}
    voff = tex_off = nrm_off = 0
    taken = False
    for geom in find_all(root, 'geometry'):
        mesh = child(geom, 'mesh')
        if mesh is None or 'coll' in geom.get('id', '').lower() or taken:
            continue
        taken = True
        sources = {}
        for src in mesh:
            if strip(src.tag) != 'source':
                continue
            arr = child(src, 'float_array')
            if arr is None or not arr.text:
                continue
            vals = [float(x) for x in arr.text.split()]
            stride = 3
            tc = child(src, 'technique_common')
            if tc is not None:
                acc = child(tc, 'accessor')
                if acc is not None:
                    stride = int(acc.get('stride', '3'))
            sources[src.get('id')] = (vals, stride)
        verts = child(mesh, 'vertices')
        vpos_id = None
        if verts is not None:
            for inp in verts:
                if strip(inp.tag) == 'input' and inp.get('semantic') == 'POSITION':
                    vpos_id = inp.get('source').lstrip('#')
            vert_id = verts.get('id')
        if vpos_id is None:
            continue
        pos, _ = sources[vpos_id]
        # posições
        def conv(x, y, z):
            if up == 'Z':
                return (x * scale, z * scale, -y * scale)
            return (x * scale, y * scale, z * scale)
        pcount = len(pos) // 3
        for i in range(pcount):
            x, y, z = conv(pos[i * 3], pos[i * 3 + 1], pos[i * 3 + 2])
            obj_lines.append('v %.5f %.5f %.5f' % (x, y, z))
        tex_list = []
        nrm_list = []
        for prim in mesh:
            kind = strip(prim.tag)
            if kind not in ('triangles', 'polylist', 'polygons'):
                continue
            inputs = []
            maxoff = 0
            for inp in prim:
                if strip(inp.tag) == 'input':
                    o = int(inp.get('offset', '0'))
                    maxoff = max(maxoff, o)
                    inputs.append((inp.get('semantic'), inp.get('source').lstrip('#'), o, int(inp.get('set', '0'))))
            stride = maxoff + 1
            p_el = child(prim, 'p')
            if p_el is None or not p_el.text:
                continue
            idx = [int(i) for i in p_el.text.split()]
            if kind == 'polylist':
                vc = [int(v) for v in child(prim, 'vcount').text.split()]
            else:
                vc = [3] * (len(idx) // stride // 3)
            sem = {}
            for s, src, o, st in inputs:
                if s in ('VERTEX', 'NORMAL', 'TEXCOORD') and (s not in sem):
                    sem[s] = (src, o)
            tcs = None
            if 'TEXCOORD' in sem:
                tcs = sources[sem['TEXCOORD'][0]]
                for i in range(len(tcs[0]) // tcs[1]):
                    obj_lines.append('vt %.5f %.5f' % (tcs[0][i * tcs[1]], tcs[0][i * tcs[1] + 1]))
            nrs = None
            if 'NORMAL' in sem:
                nrs = sources[sem['NORMAL'][0]]
                for i in range(len(nrs[0]) // 3):
                    x, y, z = conv(nrs[0][i * 3], nrs[0][i * 3 + 1], nrs[0][i * 3 + 2])
                    obj_lines.append('vn %.5f %.5f %.5f' % (x / scale if scale else x, y / scale if scale else y, z / scale if scale else z))
            sym = prim.get('material') or 'default'
            mat_id = symbol_to_mat.get(sym, sym)
            eff = materials.get(mat_id)
            tex = effects.get(eff)
            tex_file = images.get(tex, tex) if tex else None
            mtl_name = re.sub(r'\W', '_', sym)
            if mtl_name not in mtl:
                mtl[mtl_name] = tex_file
            obj_lines.append('usemtl ' + mtl_name)
            pos_off = sem['VERTEX'][1]
            cursor = 0
            for n in vc:
                corners = []
                for k in range(n):
                    base_i = (cursor + k) * stride
                    vi = idx[base_i + pos_off] + voff + 1
                    ti = (idx[base_i + sem['TEXCOORD'][1]] + tex_off + 1) if tcs else None
                    ni = (idx[base_i + sem['NORMAL'][1]] + nrm_off + 1) if nrs else None
                    if ti and ni:
                        corners.append('%d/%d/%d' % (vi, ti, ni))
                    elif ti:
                        corners.append('%d/%d' % (vi, ti))
                    elif ni:
                        corners.append('%d//%d' % (vi, ni))
                    else:
                        corners.append('%d' % vi)
                cursor += n
                for k in range(1, n - 1):
                    # inverte a ordem para manter a face para fora após trocar os eixos
                    obj_lines.append('f %s %s %s' % (corners[0], corners[k + 1], corners[k]))
            if tcs:
                tex_off += len(tcs[0]) // tcs[1]
            if nrs:
                nrm_off += len(nrs[0]) // 3
        voff += pcount
    # mtl e texturas
    lines = ['mtllib %s.mtl' % name] + obj_lines
    open(os.path.join(out_dir, name + '.obj'), 'w').write('\n'.join(lines))
    m_lines = []
    for mname, tex in mtl.items():
        m_lines.append('newmtl ' + mname)
        m_lines.append('Kd 1 1 1')
        if tex:
            fname = os.path.basename(tex.replace('file://', '').replace('%20', ' '))
            found = None
            for dirpath, _, files in os.walk(base):
                for f in files:
                    if f.lower() == fname.lower() or f.lower() == fname.lower().replace('_td', '3td'):
                        found = os.path.join(dirpath, f)
            if not found:
                # nome com 3td_ perdendo o 3: tenta por sufixo
                for dirpath, _, files in os.walk(base):
                    for f in files:
                        if f.lower().endswith(fname.lower().lstrip('_').lstrip('3')) or fname.lower().endswith(f.lower()):
                            found = os.path.join(dirpath, f)
            if found:
                shutil.copy(found, os.path.join(out_dir, os.path.basename(found)))
                m_lines.append('map_Kd ' + os.path.basename(found))
            else:
                print('  textura nao achada:', tex)
    open(os.path.join(out_dir, name + '.mtl'), 'w').write('\n'.join(m_lines))
    print(name, 'v=', voff, 'materiais', list(mtl.keys()))


for dirpath, _, files in os.walk(SRC):
    for f in files:
        if f.lower().endswith('.dae'):
            name = os.path.splitext(f)[0]
            if name in NAMES:
                convert(os.path.join(dirpath, f), os.path.join(OUT, name), name)
