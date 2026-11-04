"""Read the implemented economy and write Phase B tables; never touch saves.

Phase A remains the historical proposal. This adds the approved larger bags,
linked hand/deposit cadence, fixed objectives and two example purchase routes.
"""
import ast
import json
import math
import re
from pathlib import Path
from incremental_phase_a import ROOMS, money, table

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/balance"


def dictionary(source, name):
    return ast.literal_eval(re.search(r"const " + name + r" := (\{.*?\n\})", source, re.S)[1])


def main():
    source = (ROOT / "resources/upgrades/incremental_rules.gd").read_text(encoding="utf-8")
    costs = dictionary(source, "COSTS")
    rewards = dictionary(source, "OBJECTIVE_REWARDS")
    costs |= {"broom": [150], "vacuum": [1200], "broom_speed": [125, 300], "broom_width": [150, 350]}
    # Purchase stages are an example of access, not a forced route. Both middle
    # auditoriums open together; the player can choose their order.
    route = [
        [("reinforced_bag",0),("quick_hands",0),("reinforced_bag",1),("multi_pickup",0),("recycle_value",0),("manual_reach",0),("sprint",0),("quick_hands",1)],
        [],
        [("broom",0),("reinforced_bag",2),("broom_speed",0),("broom_width",0)],
        [("vacuum",0),("recycle_value",1),("vacuum_reach",0),("vacuum_battery",0),("quick_hands",2),("manual_reach",1),("sealed_bags",0)],
        [("recycle_value",2),("reinforced_bag",3),("multi_pickup",1),("vacuum_battery",1),("vacuum_recharge",0),("broom_speed",1),("broom_width",1),("sprint",1),("all_seeing_eye",0)],
        [("recycle_value",3),("reinforced_bag",4),("vacuum_reach",1),("vacuum_battery",2),("vacuum_recharge",1),("multi_pickup",2),("quick_hands",3),("manual_reach",2),("all_seeing_eye",1),("sealed_bags",1),("sprint",2)],
        [],
        [("multi_pickup",3),("quick_hands",4),("manual_reach",3),("vacuum_reach",2),("vacuum_recharge",2),("sprint",3),("sprint",4),("all_seeing_eye",2),("sealed_bags",2),("sealed_bags",3)],
        [("vacuum_reach",3),("vacuum_battery",3),("vacuum_recharge",3),("sealed_bags",4)],
    ]
    base = [n + g*2 for _, n, g, *_ in ROOMS]
    assert sum(base) == 8749 and sum(n+g for _,n,g,*_ in ROOMS) == 8000
    assert sum(rewards.values()) == 1200
    total_cost = sum(map(sum, costs.values()))
    all_purchases = sum(map(len, costs.values()))
    assert total_cost == 26570 and all_purchases == 53

    def simulate(ordinary):
        planned = [list(items) for items in route]
        if ordinary:
            # Vacuum first; recycle x2 only after reaching the office, x3 in the
            # lobby. Keep the final expensive convenience tiers optional.
            planned[0].remove(("recycle_value",0))
            planned[2] = [("vacuum",0),("recycle_value",0)] + planned[2]
            planned[3].remove(("vacuum",0))
            planned[3].remove(("recycle_value",1))
            planned[5].insert(0,("recycle_value",1))
            excluded = {("recycle_value",2),("recycle_value",3),("vacuum_reach",3),
                        ("vacuum_battery",3),("vacuum_recharge",3),("sealed_bags",3),
                        ("sealed_bags",4),("sprint",4),("all_seeing_eye",2)}
            planned = [[item for item in items if item not in excluded] for items in planned]
        pending, cash, gross, spent, mult, objects = [], 0, 0, 0, 1, 0
        purchases, ledger = [], []
        core_rewards = {0:50,3:100,4:100,5:100,7:150}
        for zone, (name,n,g,*_) in enumerate(ROOMS):
            pending.extend(planned[zone])
            def buy():
                nonlocal cash, spent, mult
                while pending and cash >= costs[pending[0][0]][pending[0][1]]:
                    key, level = pending.pop(0)
                    value = costs[key][level]
                    cash -= value
                    spent += value
                    purchases.append([objects,name,key,level+1,money(value),money(cash)])
                    if key == "recycle_value": mult = level+2
            buy()
            for i in range(n+g):
                large = ((i+1)*g//(n+g)) > (i*g//(n+g))
                amount = (2 if large else 1)*mult
                cash += amount
                gross += amount
                objects += 1
                buy()
            cash += core_rewards.get(zone,0)
            gross += core_rewards.get(zone,0)
            buy()
            ledger.append([name,objects,money(gross),money(spent),money(cash),mult,len(purchases)])
        assert not pending
        return {"gross_cents":gross,"spent_cents":spent,"cash_cents":cash,
                "purchase_count":len(purchases),"ledger":ledger,"purchases":purchases}

    ordinary, efficient = simulate(True), simulate(False)
    assert efficient["spent_cents"] == total_cost
    assert .70 <= ordinary["purchase_count"]/all_purchases <= .85
    capacities = [25,40,65,100,150,220]
    zone_rows, accumulated = [], 0
    for name,n,g,*_ in ROOMS:
        accumulated += n+2*g
        zone_rows.append([name,n,g,money(n+2*g),money(accumulated)] + [math.ceil((n+2*g)/c) for c in capacities])
    manager_source = (ROOT/"scripts/gameplay_manager.gd").read_text(encoding="utf-8")
    delivery_base = float(re.search(r"base_deposit_interval := ([0-9.]+)",manager_source)[1])
    cadence = [[level,capacity,f"{cooldown:.2f}",f"{delivery_base*cooldown/.75:.4f}",f"{capacity*delivery_base*cooldown/.75:.2f}"]
               for level,(capacity,cooldown) in enumerate(zip(capacities,[.75,.60,.50,.40,.32,.25]))]
    report = {
        "built_objects":6270,"reserved_objects":1730,"built_base_cents":sum(base[:-1]),
        "reserved_base_cents":base[-1],"all_purchase_cost_cents":total_cost,"all_purchases":all_purchases,
        "fixed_objective_rewards_cents":sum(rewards.values()),"ordinary":ordinary,"efficient":efficient,
    }
    (OUT/"incremental_phase_b_results.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
    sections = ["# Fase B — economía implementada (03-11-2026)",
        "Estas tablas sustituyen las capacidades e hipótesis de entrega de la propuesta histórica de Fase A. Se calculan desde los precios y recompensas activos. Los tiempos de entrega son matemáticos, no una duración medida de la partida.",
        f"53 compras, coste total **{money(total_cost)}**. Recompensas fijas de objetivos: hasta **{money(sum(rewards.values()))}**, sin multiplicador de reciclaje. Las dos rutas solo cuentan los **5,00** de los objetivos de limpieza, acreditados al terminar cada zona para simplificar (el juego los concede al cumplirse el objetivo). No cuentan documentos, películas, recreativas, coleccionables ni objetos perdidos.",
        "## Salas y descargas mínimas", "Una botella es un objeto, consume dos unidades de bolsa y sale en un único pulso que paga 0,02 × reciclaje. Las columnas de capacidad cuentan viajes mínimos por volumen; una bolsa puede exigir una descarga parcial adicional según el orden de objetos. La sala final es una reserva: no se genera ni financia la versión actual.",
        table(["Zona","Normales","Grandes","Base","Base acumulada"]+[f"Bolsa {c}" for c in capacities],zone_rows),
        "## Progresión de bolsa y entrega", "Las ramas de bolsa y manos son independientes; la tabla las empareja solo para comparar. Vaciar una bolsa llena de objetos grandes requiere menos pulsos. Un saco sellado conserva la entrega completa al llegar a una papelera.",
        table(["Nivel comprado","Capacidad bolsa","Recogida s","Entrega s/objeto","Descarga bolsa de pequeños s"],cadence),
        "## Ruta ordinaria: aspiradora primero", f"Compras seleccionadas: **{ordinary['purchase_count']}/53 ({ordinary['purchase_count']/53:.1%})**. Retrasa el reciclaje, compra pronto la aspiradora y deja los últimos niveles de comodidad. Es un ejemplo de elección, no un límite artificial de compras.",
        table(["Zona terminada","Objetos acumulados","Ingresos acumulados","Gasto","Saldo","Reciclaje","Compras"],ordinary["ledger"]),
        "## Ruta de reinversión temprana", "Compra reciclaje antes y reinvierte pronto. Demuestra que las 53 compras son asequibles con el cine completo; no promete que cualquier orden de compra permita obtenerlas. Las filas anteriores a la sala final representan únicamente el contenido construido.",
        table(["Zona terminada","Objetos acumulados","Ingresos acumulados","Gasto","Saldo","Reciclaje","Compras"],efficient["ledger"]),
        "## Límites", "Sin reciclaje, toda la basura del cine completo da 87,49. Incluso ×2 gratuito desde el primer objeto, más todos los objetivos, solo daría 186,98, por debajo de 265,70. No hay gasto obligatorio para abrir puertas ni para obtener la maza: siempre se puede terminar limpiando con la mano. La sala final, su tiempo y sus ingresos siguen pendientes de construcción. La cadencia real de aspiración y las caídas ya se ejecutan en Godot; las tasas globales de limpieza y la duración final necesitan una partida completa. La aspiradora recoge todas las categorías por decisión posterior a Fase A; la escoba solo agrupa y nunca recoge ni paga."]
    (OUT/"INCREMENTAL_PHASE_B_TABLES.md").write_text("\n\n".join(sections)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k not in ("ordinary","efficient")},indent=2))
    print("ordinary",ordinary["purchase_count"],ordinary["gross_cents"],ordinary["spent_cents"])
    print("efficient",efficient["purchase_count"],efficient["gross_cents"],efficient["spent_cents"])


if __name__ == "__main__": main()
