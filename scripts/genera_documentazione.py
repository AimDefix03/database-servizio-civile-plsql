#!/usr/bin/env python3
"""Legge l'estrazione del catalogo (stdin) e scrive dizionario dei dati e diagramma ER."""
import re
import sys
from collections import defaultdict
from pathlib import Path

DOCS = Path(__file__).resolve().parent.parent / "docs"

tabelle, colonne, vincoli = {}, defaultdict(list), defaultdict(list)
sezione = None
for riga in sys.stdin.read().splitlines():
    riga = riga.rstrip()
    if riga.startswith("##"):
        sezione = riga[2:]
        continue
    if not riga or sezione is None:
        continue
    if sezione == "TABELLE":
        nome, commento = riga.split("|", 1)
        tabelle[nome] = commento
    elif sezione == "COLONNE":
        t, c, tipo, nullable, commento = riga.split("|", 4)
        colonne[t].append((c.lower(), tipo, nullable, commento))
    elif sezione == "VINCOLI":
        t, tipo, nome, cols, rif, cond = riga.split("|", 5)
        rif = re.sub(r"\(([^)]*)\)", lambda m: "(" + m.group(1).lower() + ")", rif)
        vincoli[t].append((tipo, nome, [x.lower() for x in cols.split(",")] if cols else [], rif, cond.strip()))

if not tabelle:
    sys.exit("Nessuna tabella trovata: il database è installato?")

senza_commento = [f"{t}.{c}" for t in tabelle for c, _, _, d in colonne[t] if not d]
senza_commento += [t for t, d in tabelle.items() if not d]
if senza_commento:
    sys.exit("Mancano i commenti per: " + ", ".join(senza_commento)
             + "\nAggiungerli in sql/01_schema/03_commenti.sql")

def pk(t):
    return next((v[2] for v in vincoli[t] if v[0] == "P"), [])

def unici(t):
    return [v[2] for v in vincoli[t] if v[0] in ("P", "U")]

def chiave(t, col):
    parti = []
    if col in pk(t):
        parti.append("PK")
    for tipo, _, cols, rif, _ in vincoli[t]:
        if tipo == "R" and col in cols:
            parti.append(f"FK → {rif}")
        elif tipo == "U" and col in cols and len(cols) == 1:
            parti.append("UK")
    return ", ".join(parti)

def md(testo):
    return testo.replace("|", "\\|")

# ---- dizionario dei dati ------------------------------------------------------
o = ["# Dizionario dei dati", "",
     "> File generato da `scripts/genera-documentazione.sh` a partire dal catalogo del database.",
     "> Non modificarlo a mano: aggiornare i commenti in `sql/01_schema/03_commenti.sql` e rigenerare.", "",
     f"Tabelle: {len(tabelle)}. Diagramma delle relazioni: [diagramma_er.md](diagramma_er.md).", "",
     "## Indice", ""]
o += [f"- [{t}](#{t.lower().replace('_', '-')})" for t in tabelle]
o.append("")
for t, desc in tabelle.items():
    o += [f"## {t}", "", desc, "",
          "| Colonna | Tipo | Null | Chiave | Descrizione |", "|---|---|---|---|---|"]
    for c, tipo, nullable, d in colonne[t]:
        o.append(f"| `{c}` | {tipo} | {'sì' if nullable == 'Y' else 'no'} | {chiave(t, c)} | {md(d)} |")
    o.append("")
    composite = [("Chiave primaria", v[2]) for v in vincoli[t] if v[0] == "P" and len(v[2]) > 1]
    composite += [("Unicità", v[2]) for v in vincoli[t] if v[0] == "U" and len(v[2]) > 1]
    for etichetta, cols in composite:
        o.append(f"{etichetta} composta: `{', '.join(cols)}`.")
        o.append("")
    regole = [(n, cond) for tipo, n, _, _, cond in vincoli[t] if tipo == "C"]
    if regole:
        o += ["Vincoli di controllo:", ""]
        o += [f"- `{n.lower()}`: `{md(re.sub(r'\s+', ' ', cond))}`" for n, cond in sorted(regole)]
        o.append("")
(DOCS / "dizionario_dati.md").write_text("\n".join(o).rstrip() + "\n", encoding="utf-8")

# ---- diagramma ER (Mermaid) ---------------------------------------------------
def tipo_er(tipo):
    return re.sub(r"\(.*\)", "", tipo)

er = ["# Diagramma entità-relazione", "",
      "> File generato da `scripts/genera-documentazione.sh` a partire dal catalogo del database.",
      "> Non modificarlo a mano. Descrizione di tabelle e colonne in [dizionario_dati.md](dizionario_dati.md).", "",
      "```mermaid", "erDiagram"]
for t in tabelle:
    er.append(f"    {t} {{")
    for c, tipo, _, _ in colonne[t]:
        sigle = []
        if c in pk(t):
            sigle.append("PK")
        if any(v[0] == "R" and c in v[2] for v in vincoli[t]):
            sigle.append("FK")
        er.append(f"        {tipo_er(tipo)} {c}" + (f" {','.join(sigle)}" if sigle else ""))
    er.append("    }")
for t in tabelle:
    for tipo, _, cols, rif, _ in vincoli[t]:
        if tipo != "R":
            continue
        padre = rif.split("(")[0]
        singola = any(set(cols) == set(u) for u in unici(t))
        cardinalita = "||--o|" if singola else "||--o{"
        er.append(f'    {padre} {cardinalita} {t} : "{",".join(cols)}"')
er += ["```", ""]
(DOCS / "diagramma_er.md").write_text("\n".join(er), encoding="utf-8")
print(f"Scritti dizionario_dati.md ({len(tabelle)} tabelle) e diagramma_er.md")
