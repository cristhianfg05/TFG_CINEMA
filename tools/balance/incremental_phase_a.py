"""Read-only gameplay audit and reproducible design calculations, not runtime tuning.

Writes review tables under docs/balance; never edits the game catalog or saves.
Run with the project's Stable Audio Python or any Python 3.11+.
"""
import csv
import io
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/balance"
CATALOG = ROOT / "resources/upgrades/upgrade_catalog.gd"
PRICES = {
    "quick_hands": [20, 45, 85, 140, 220],
    "reinforced_bag": [25, 60, 125, 225, 800],
    "sealed_bags": [75, 180, 350, 400, 900],
    "sprint": [50, 125, 250, 425, 1000],
    "multi_pickup": [95, 220, 425, 1200],
    "manual_reach": [35, 90, 180, 300],
    "recycle_value": [300, 800, 1400, 1800],
    "all_seeing_eye": [100, 250, 700],
    "vacuum_reach": [225, 450, 850, 3000],
    "vacuum_battery": [175, 350, 650, 2200],
    "vacuum_recharge": [150, 300, 550, 2000],
}
# Visual corridor names, not the historical reversed save IDs.
# name, small, large, old_small, old_large, expected capacity, effective rate,
# bin round-trip seconds, search seconds, target tool
ROOMS = [
    ("Sala 1",600,50,380,20,30,1.15,10,90,"Manual"),
    ("Ala derecha",255,25,105,15,50,1.5,8,35,"Manual"),
    ("Despacho",36,4,16,2,50,1.5,5,20,"Manual / compra escoba"),
    ("Sala 2",990,110,420,60,80,2.5,16,150,"Escoba + manual; aspiradora a mitad"),
    ("Sala 3 Acción",945,105,410,30,120,3.4,18,180,"Aspiradora + manual"),
    ("Entrada y vestíbulo",1350,150,520,35,180,3.6,14,210,"Escoba + manual / aspiradora"),
    ("Ala izquierda",185,15,80,10,180,3.6,8,35,"Escoba + manual"),
    ("Sala 4 Miedo",1320,130,640,20,180,3.5,22,300,"Aspiradora + manual / escoba"),
    ("Sala final (reserva)",1570,160,0,0,180,4.0,25,360,"Mixto; sala aún inexistente"),
]
STAGES = {
    "quick_hands": [0,0,3,5,7], "reinforced_bag": [0,0,2,4,5],
    "sealed_bags": [3,5,7,7,8], "sprint": [0,4,5,7,7],
    "multi_pickup": [0,4,5,7], "manual_reach": [0,3,5,7],
    "recycle_value": [0,3,4,5], "all_seeing_eye": [4,5,7],
    "vacuum_reach": [3,5,7,8], "vacuum_battery": [3,4,5,8],
    "vacuum_recharge": [4,5,7,8],
}
REASONS = {
    "quick_hands":"Mantener ritmo y escalones; retocar costes frente a densidad mayor.",
    "reinforced_bag":"Capacidad propuesta 20 inicial y 30/50/80/120/180; reducir viajes.",
    "sealed_bags":"Conveniencia opcional; abaratar niveles tardíos de escaso retorno.",
    "sprint":"Viajes más largos, útil antes del final; conservar velocidades reales.",
    "multi_pickup":"Sinergia con pilas de escoba; conservar 2/3/4/5 objetivos por acción.",
    "manual_reach":"Mantener prestaciones; costes similares a la referencia de escala.",
    "recycle_value":"×2/3/4/5; retrasar primera bola de nieve y asegurar retorno de los últimos.",
    "all_seeing_eye":"Ayuda al 100%; opcional y más asequible al final.",
    "vacuum_reach":"2/2,5/3,25/4 m; último nivel opcional caro para mantener decisiones al final.",
    "vacuum_battery":"Conservar 12/18/26/40 s; último nivel opcional para sesiones largas.",
    "vacuum_recharge":"Conservar 1,5/2/3/4; autonomía tardía, sin mejora de velocidad de entrega.",
}

def money(cents):
    return f"{cents / 100:.2f}".replace(".", ",")

def table(headers, rows):
    return "\n".join(["| " + " | ".join(map(str, headers)) + " |",
                      "| " + " | ".join("---" for _ in headers) + " |"] +
                     ["| " + " | ".join(map(str, row)) + " |" for row in rows])

def main():
    branches = [json.loads(line.strip().rstrip(","))
                for line in CATALOG.read_text(encoding="utf-8").splitlines()
                if line.strip().startswith('{"id":')]
    OUT.mkdir(parents=True, exist_ok=True)
    rows, totals = [], []
    for b in branches:
        for i, cost in enumerate(b["costs"]):
            new = PRICES.get(b["id"], [0]*len(b["costs"]))[i]
            value = b["values"][i]
            if b["id"] == "reinforced_bag":
                value = [30,50,80,120,180][i]
            effect = f'{value} {b["unit"]}'
            if b["id"] == "sprint":
                effect += f'; aguante {b["secondary"][i]} s; recarga {b["recharge"][i]} s'
            if b["id"] == "all_seeing_eye":
                effect += f'; enfriamiento {b["cooldowns"][i]} s'
            rows.append([b["id"],b["title"],i+1,cost,money(cost),
                         money(new) if new else "Retirar",effect,
                         f'{new/8749*100:.2f}%' if new else "—",
                         ROOMS[STAGES[b["id"]][i]][0] if new else "—",
                         REASONS.get(b["id"],"Boti descartado; compensar compras previas.")])
        totals.append([b["title"],sum(b["costs"]),money(sum(b["costs"])),
                       money(sum(PRICES[b["id"]])) if b["id"] in PRICES else "Retirar"])
    headers = ["ID","Mejora","Nivel comprable","Precio actual (monedas antiguas)",
               "Equivalente /100 (monedas nuevas)","Recomendado (monedas nuevas)",
               "Beneficio recomendado","% de 87,49 base","% ingreso ruta",
               "Momento recomendado","Justificación"]
    zone_rows, compare, cumulative = [], [], 0
    for name,n,g,on,og,cap,rate,trip,search,tool in ROOMS:
        count, units = n+g, n+2*g
        cumulative += units
        seconds = count/rate + count*.1 + math.ceil(units/cap)*trip + search
        zone_rows.append([name,n,g,money(units),money(cumulative),
                          math.ceil(units/10),math.ceil(units/60),math.ceil(units/cap),
                          f"{seconds/60:.1f}",tool])
        compare.append([name,f"{on}/{og}",on+og,on+2*og,f"{count/(on+og):.2f}×" if on+og else "Reserva",
                        f"{(count/2.4+count*.1+math.ceil(units/cap)*trip+search)/60:.1f}",
                        f"{(count/3.2+count*.1+math.ceil(units/cap)*trip+search)/60:.1f}",
                        f"{(count/4.0+count*.1+math.ceil(units/cap)*trip+search)/60:.1f}"])
    # Deterministic economic route. Normal/large items interleaved evenly;
    # upgrades bought only after deposit, tool shop accessible at office.
    route = [
        (0,[("reinforced_bag",0),("quick_hands",0),("reinforced_bag",1),("multi_pickup",0),("recycle_value",0),("manual_reach",0),("sprint",0),("quick_hands",1)]),
        (2,[("broom",0),("reinforced_bag",2),("broom_speed",0),("broom_width",0)]),
        (3,[("vacuum",0),("recycle_value",1),("vacuum_reach",0),("vacuum_battery",0),("quick_hands",2),("manual_reach",1),("sealed_bags",0)]),
        (4,[("recycle_value",2),("reinforced_bag",3),("multi_pickup",1),("vacuum_battery",1),("vacuum_recharge",0),("broom_speed",1),("broom_width",1),("sprint",1),("all_seeing_eye",0)]),
        (5,[("recycle_value",3),("reinforced_bag",4),("vacuum_reach",1),("vacuum_battery",2),("vacuum_recharge",1),("multi_pickup",2),("quick_hands",3),("manual_reach",2),("all_seeing_eye",1),("sealed_bags",1),("sprint",2)]),
        (7,[("multi_pickup",3),("quick_hands",4),("manual_reach",3),("vacuum_reach",2),("vacuum_recharge",2),("sprint",3),("sprint",4),("all_seeing_eye",2),("sealed_bags",2),("sealed_bags",3)]),
        (8,[("vacuum_reach",3),("vacuum_battery",3),("vacuum_recharge",3),("sealed_bags",4)]),
    ]
    costs = PRICES | {"broom":[150],"vacuum":[1200],"broom_speed":[125,300],"broom_width":[150,350]}
    pending, cash, gross, spent, mult, objects = [],0,0,0,1,0
    purchases, ledger = [], []
    for zone,(name,n,g,*_) in enumerate(ROOMS):
        for stage,items in route:
            if stage==zone: pending.extend(items)
        def buy():
            nonlocal cash, spent, mult
            while pending and cash >= costs[pending[0][0]][pending[0][1]]:
                key,level=pending.pop(0); price=costs[key][level]
                cash-=price; spent+=price
                purchases.append([objects,name,key,level+1,money(price),money(cash)])
                if key=="recycle_value": mult=level+2
        buy()
        count=n+g
        for index in range(count):
            large=((index+1)*g//count) > (index*g//count)
            amount=(2 if large else 1)*mult
            cash+=amount; gross+=amount; objects+=1
            buy()
        ledger.append([name,objects,money(gross),money(spent),money(cash),mult,len(pending)])
    total_recommended=sum(map(sum,costs.values()))
    current_total=sum(sum(b["costs"]) for b in branches)+2250
    assert objects==8000 and sum(r[1]+2*r[2] for r in ROOMS)==8749
    assert not pending and spent==total_recommended
    assert sum(len(v) for v in costs.values())==len(purchases)
    for row in rows:
        price = PRICES[row[0]][row[2]-1] if row[0] in PRICES else 0
        row.insert(8, f"{price/gross*100:.2f}%" if price else "—")
    writer_buffer = io.StringIO()
    writer = csv.writer(writer_buffer)
    writer.writerow(headers); writer.writerows(rows)
    (OUT/"incremental_mejoras_niveles.csv").write_text(writer_buffer.getvalue(),encoding="utf-8-sig")
    sections=["# Fase A — tablas calculadas (03-11-2026)",
        "Valores de diseño propuestos; no aplicados al juego. Importes nuevos en monedas con dos decimales. La columna /100 es solo referencia matemática.",
        "## Cada nivel existente",table(headers,rows),
        "## Totales por rama",table(["Rama","Actual","Referencia /100","Recomendado"],totals),
        f"Total actual con herramientas y Boti: {current_total} monedas antiguas. Total recomendado sin Boti y con escoba: {money(total_recommended)}. No sumar Boti a la propuesta.",
        "## Salas y viajes", "Los viajes son un mínimo matemático por volumen; repartir los objetos grandes puede añadir descargas parciales. Capacidad propuesta usada por sala: 30,50,50,80,120,180,180,180,180.",
        table(["Zona","Normales","Grandes","Base","Base acumulada","Viajes bolsa10","Viajes bolsa60","Viajes propuesta","Minutos ruta","Herramienta"],zone_rows),
        "## Comparación con las mismas mejoras", "Minutos modelados: manual efectiva 2,4 objetos/s, escoba+manual 3,2, aspiradora+manual de grandes 4,0. Tasas hipotéticas incluyendo encuadre y batería; no benchmarks. Se añade entrega, viajes y búsqueda de la misma zona. No representan el rendimiento inicial ni una escoba que recoja por sí sola.",
        table(["Zona","Actual N/G","Objetos actuales","Monedas actuales base","Aumento objetos","Manual min","Escoba+manual min","Aspiradora+manual min"],compare),
        "## Ruta económica de ejemplo", "Modelo por objeto depositado, distribución uniforme de grandes, sin recompensa del reloj. La compra se ejecuta en cuanto hay saldo dentro de la lista priorizada de cada etapa. Asume acceso inmediato a la tienda, no tiempo de desplazamiento. Es una ruta de asequibilidad, no una ruta obligatoria ni la estrategia óptima.",
        table(["Zona terminada","Objetos acumulados","Ingresos reales acumulados","Gasto acumulado","Saldo","Multiplicador","Compras pendientes"],ledger),
        "## Compras de esa ruta",table(["Objetos depositados acumulados","Zona","ID","Nivel comprado","Precio","Saldo posterior"],purchases),
        "## Límites del modelo", "Recaudación depende del momento de compra del reciclaje. Sin comprarlo: 87,49; con ×5 gratuito desde el primer objeto: 437,45 (techo imposible de lograr con compras reales). Sala final no generará ingresos en la versión actual: su fila es una reserva de diseño. El orden Sala2→Sala3 es una ruta posible; ambas se abren juntas."]
    (OUT/"INCREMENTAL_PHASE_A_TABLES.md").write_text("\n\n".join(sections)+"\n",encoding="utf-8")
    print(json.dumps({"current_objects":2763,"current_base":2955,"current_all_cost":current_total,"new_objects":objects,"new_base_cents":8749,"recommended_total_cents":total_recommended,"route_income_cents":gross,"route_balance_cents":cash,"purchases":len(purchases),"route_minutes":round(sum(float(r[8]) for r in zone_rows),1),"unlock_purchases":[p for p in purchases if p[2] in ["broom","vacuum","recycle_value"]]},ensure_ascii=False,indent=2))

if __name__=="__main__":
    main()
