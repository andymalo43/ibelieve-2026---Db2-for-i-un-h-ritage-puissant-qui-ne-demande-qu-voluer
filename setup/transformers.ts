// Blocs ```d2 → image SVG, compilés au build par D2 (WebAssembly, sans binaire à installer).
//
// Usage dans slides.md :
//   ```d2 {scale: 0.8, maxHeight: '18rem'}
//   ...@theme          ← insère diagrams/theme.d2 (palette seriph)
//   a -> b
//   ```
// Options : scale (taille relative, 1 par défaut), maxHeight (CSS), layout ('elk' | 'dagre'), sketch.
// Animation au clic : donner aux éléments la classe etape2, etape3… (en plus de leur classe de style,
// ex. {class: [bloc; etape2]}) ; ils apparaissent un clic après l'autre, sans changer la disposition.
// Logos : `icon: @logo:sinapse.png` dans un bloc D2 devient une URL factice pour D2, puis l'image de public/logos/
// est incorporée en data URI dans le SVG produit (autonome). À coupler avec `shape: image`.
// Rendu par components/D2Diagram.vue (SVG en ligne : polices et taille fiables, contrairement à <img>).
import { readdir, readFile } from 'node:fs/promises'
import { extname, join } from 'node:path'
import { defineTransformersSetup } from '@slidev/types'
import { D2 } from '@terrastruct/d2'

let d2: D2 | undefined
let queue: Promise<unknown> = Promise.resolve()
const cache = new Map<string, string>()

async function getD2() {
  if (!d2) {
    d2 = new D2()
    await d2.ready
    // Le worker ne doit pas retenir le processus : sinon `slidev build` ne rend jamais la main.
    ;(d2 as any).worker?.unref?.()
  }
  return d2
}

// Fichiers importables (`...@theme`) : tout diagrams/*.d2
async function loadFs(root: string) {
  const dir = join(root, 'diagrams')
  const fs: Record<string, string> = {}
  for (const f of await readdir(dir).catch(() => [] as string[])) {
    if (f.endsWith('.d2'))
      fs[f] = await readFile(join(dir, f), 'utf8')
  }
  return fs
}

function parseMeta(info: string): Record<string, any> {
  const m = info.match(/\{(.*)\}/)
  if (!m)
    return {}
  // Même syntaxe que les blocs mermaid de Slidev : un objet JS littéral
  return new Function(`return {${m[1]}}`)()
}

async function render(code: string, meta: Record<string, any>, root: string) {
  const key = JSON.stringify([code, meta, await loadFs(root)])
  if (cache.has(key))
    return cache.get(key)!
  const run = async () => {
    const d = await getD2()
    const fs = await loadFs(root)
    // `...@nom` seul sur sa ligne : inclusion textuelle, car les globs D2 (style des flèches)
    // ne traversent pas un import.
    let source = code.replace(/^\s*\.\.\.@([\w-]+)\s*$/gm, (line, name) => fs[`${name}.d2`] ?? line)
    // D2 limite la longueur des clés : on laisse une URL factice, remplacée par la data URI après rendu.
    const logos = [...new Set([...source.matchAll(/@logo:([\w.-]+)/g)].map(m => m[1]))]
    for (const fichier of logos)
      source = source.replaceAll(`@logo:${fichier}`, `https://logo.local/${fichier}`)
    const result = await d.compile(
      { fs: { ...fs, index: source }, inputPath: 'index' },
      { layout: meta.layout ?? 'elk', sketch: meta.sketch ?? false, pad: 8, center: true },
    )
    let svg = await d.render(result.diagram, { ...result.renderOptions, pad: 8, noXMLTag: true })
    for (const fichier of logos) {
      const octets = await readFile(join(root, 'public', 'logos', fichier))
      const mime = ({ '.png': 'image/png', '.jpg': 'image/jpeg', '.svg': 'image/svg+xml' } as Record<string, string>)[extname(fichier)] ?? 'image/png'
      svg = svg.replaceAll(`https://logo.local/${fichier}`, `data:${mime};base64,${octets.toString('base64')}`)
    }
    // Taille naturelle (unités D2 ≈ px du canevas Slidev) × scale ; le CSS du composant borne ensuite.
    const [, , w, h] = (svg.match(/viewBox="([^"]+)"/)?.[1] ?? '0 0 600 300').split(/\s+/).map(Number)
    const k = meta.scale ?? 1
    svg = svg.replace('<svg ', `<svg width="${Math.round(w * k)}" height="${Math.round(h * k)}" `)
    const b64 = Buffer.from(svg).toString('base64')
    const maxHeight = meta.maxHeight ? ` max-height="${meta.maxHeight}"` : ''
    // Étapes révélées au clic : la plus haute classe etapeN utilisée dans le source
    const etapes = Math.max(1, ...[...code.matchAll(/\betape(\d+)\b/g)].map(m => Number(m[1])))
    const steps = etapes > 1 ? ` :steps="${etapes}"` : ''
    return `<D2Diagram svg="${b64}"${maxHeight}${steps} />`
  }
  // Le wrapper D2 ne gère qu'une requête à la fois : on sérialise.
  const html = await (queue = queue.then(run, run)) as string
  cache.set(key, html)
  return html
}

export default defineTransformersSetup(() => ({
  pre: [],
  preCodeblock: [],
  postCodeblock: [],
  post: [],
  codeblocks: [
    async ({ info, code, options }) => {
      if (!/^d2\b/.test(info.trim()))
        return
      return render(code, parseMeta(info), options.userRoot)
    },
  ],
}))
