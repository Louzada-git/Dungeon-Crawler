extends RefCounted
class_name InventoryData

signal changed
const CAPACITY: float = 18.0
const COMFORT: float = 11.0
var stacks: Dictionary = {}
var equipped: String = ""

func weight() -> float:
 var total: float = 0.0
 for id in stacks:
  total += float(Items.info(id).get("weight", 0.0)) * int(stacks[id])
 return total

func count(id: String) -> int:
 return int(stacks.get(id, 0))

func add(id: String, amount: int = 1) -> int:
 if not Items.DATA.has(id) or amount <= 0:
  return 0
 var unit: float = Items.info(id)["weight"]
 var fit: int = maxi(0, int(floor((CAPACITY - weight() + 0.0001) / unit)))
 var accepted: int = mini(amount, fit)
 if accepted > 0:
  stacks[id] = count(id) + accepted
  changed.emit()
 return accepted

func remove(id: String, amount: int = 1) -> bool:
 if amount <= 0 or count(id) < amount:
  return false
 stacks[id] = count(id) - amount
 if count(id) == 0:
  stacks.erase(id)
  if equipped == id:
   equipped = ""
 changed.emit()
 return true

func equip(id: String) -> bool:
 if count(id) == 0 or not Items.info(id).has("damage"):
  return false
 equipped = id
 changed.emit()
 return true

func unequip() -> void:
 if equipped != "":
  equipped = ""
  changed.emit()

func transfer_from(source: Dictionary, id: String, requested: int) -> int:
 var accepted: int = add(id, mini(int(source.get(id, 0)), requested))
 if accepted > 0:
  source[id] = int(source[id]) - accepted
  if source[id] <= 0:
   source.erase(id)
 return accepted

func snapshot() -> Dictionary:
 return {"stacks":stacks.duplicate(true), "equipped":equipped}

func restore(data: Dictionary) -> bool:
 var raw = data.get("stacks", {})
 if not raw is Dictionary:
  return false
 var candidate: Dictionary = {}
 var total: float = 0.0
 for id in raw:
  if not Items.DATA.has(id) or not (raw[id] is int or raw[id] is float):
   return false
  var n: int = int(raw[id])
  if n < 1 or n > 10000 or float(raw[id]) != float(n):
   return false
  candidate[id] = n
  total += n * float(Items.info(id)["weight"])
 if total > CAPACITY + 0.001:
  return false
 var next_equipped: String = str(data.get("equipped", ""))
 if next_equipped != "" and (not candidate.has(next_equipped) or not Items.info(next_equipped).has("damage")):
  return false
 stacks = candidate
 equipped = next_equipped
 changed.emit()
 return true
