extends UiWindow
class_name UiShopWindow
## The merchant's window (ShopSystem): his stock on the left, the backpack on
## the right, prices in coins. Double click buys or sells one; dragging a stack
## to the other side buys or sells all of it that it can.

var game
var stock_list: UiItemList
var bag_list: UiItemList
var coins_label: Label
var detail: Label
var buy_button: Button
var buy_more_button: Button
var sell_button: Button
var sell_all_button: Button
var _last: String = ""

func _init(owner_game) -> void:
	super._init("Mercador", UiIcon.new("bag", UiStyle.ACCENT), 900, 560)
	game = owner_game
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	body.add_child(top)
	coins_label = UiStyle.label("", 15, UiStyle.ACCENT, "semibold")
	coins_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(coins_label)
	top.add_child(UiStyle.label("Duplo clique compra ou vende um  ·  arraste para o outro lado para levar tudo", 12, UiStyle.DIM))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	stock_list = UiItemList.new("loja")
	stock_list.empty_text = "O mercador não tem mais nada para vender."
	stock_list.price_of = func(id): return ShopSystem.buy_price(game.floor, id)
	var left := _column(columns, "À venda", stock_list)
	buy_button = UiStyle.button("Comprar 1", func(): buy(stock_list.selected_id, 1), 130)
	buy_more_button = UiStyle.button("Comprar 10", func(): buy(stock_list.selected_id, 10), 130)
	left.add_child(_row([buy_button, buy_more_button]))
	bag_list = UiItemList.new("loja_mochila")
	bag_list.empty_text = "Nada na mochila para vender."
	# "—" for what he does not buy and for the piece in use.
	bag_list.price_of = func(id): return ShopSystem.sell_price(id) if ShopSystem.sellable(game, id) > 0 else 0
	var right := _column(columns, "Sua mochila  ·  o que ele paga", bag_list)
	sell_button = UiStyle.button("Vender 1", func(): sell(bag_list.selected_id, 1), 130)
	sell_all_button = UiStyle.button("Vender todos", func(): sell(bag_list.selected_id, 9999), 130)
	right.add_child(_row([sell_button, sell_all_button]))
	detail = UiStyle.label("", 13, UiStyle.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(860, 40)
	body.add_child(detail)
	stock_list.item_selected.connect(func(id): _last = "loja:" + id; _refresh_detail())
	bag_list.item_selected.connect(func(id): _last = "mochila:" + id; _refresh_detail())
	stock_list.item_activated.connect(func(id): buy(id, 1))
	bag_list.item_activated.connect(func(id): sell(id, 1))
	stock_list.item_dropped.connect(func(data): sell(str(data["id"]), int(data["count"])))
	bag_list.item_dropped.connect(func(data): buy(str(data["id"]), int(data["count"])))

func _column(parent: Control, caption: String, list: UiItemList) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(col)
	col.add_child(UiStyle.caps(caption, 11, UiStyle.MUTED))
	list.custom_minimum_size = Vector2(420, 340)
	col.add_child(list)
	return col

func _row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for b in buttons:
		b.custom_minimum_size.y = 32
		row.add_child(b)
	return row

## Shows the window with this floor's stock.
func open() -> void:
	set_title("Mercador  ·  %dº andar" % game.floor if game.generated else "Mercador")
	stock_list.selected_id = ""
	bag_list.selected_id = ""
	_last = ""
	show()
	refresh()

func refresh() -> void:
	stock_list.set_items(game.shop_stock)
	var bag: Dictionary = game.inventory.stacks.duplicate()
	bag.erase("coin")
	bag_list.set_items(bag, game.inventory.equipped, game.inventory.armor)
	coins_label.text = "Vinténs: %d" % game.inventory.count("coin")
	var s: String = stock_list.selected_id
	var price: int = ShopSystem.buy_price(game.floor, s)
	buy_button.disabled = s == "" or not game.shop_stock.has(s) or game.inventory.count("coin") < price
	buy_more_button.disabled = buy_button.disabled
	var b: String = bag_list.selected_id
	sell_button.disabled = b == "" or ShopSystem.sellable(game, b) <= 0
	sell_all_button.disabled = sell_button.disabled
	_refresh_detail()

func _refresh_detail() -> void:
	var parts: PackedStringArray = _last.split(":")
	if parts.size() < 2 or parts[1] == "":
		detail.text = "O que você vender fica com ele: dá para comprar de volta. A arma em mãos e a armadura vestida não entram na venda."
		return
	var id: String = parts[1]
	var data: Dictionary = Items.info(id)
	if parts[0] == "loja":
		detail.text = "%s  ·  %s cada  ·  %s" % [data.get("name", id), coins(ShopSystem.buy_price(game.floor, id)), data.get("description", "")]
	else:
		var pay: int = ShopSystem.sell_price(id)
		var note: String = "ele paga %s cada" % coins(pay) if pay > 0 else "ele não compra isso"
		if pay > 0 and ShopSystem.sellable(game, id) < game.inventory.count(id):
			note += " (a peça em uso fica com você)"
		detail.text = "%s  ·  %s  ·  %s" % [data.get("name", id), note, data.get("description", "")]

## "1 vintém", "12 vinténs".
static func coins(n: int) -> String:
	return "%d %s" % [n, "vintém" if n == 1 else "vinténs"]

func buy(id: String, amount: int) -> void:
	if id == "":
		return
	var name: String = str(Items.info(id).get("name", id))
	var got: int = ShopSystem.buy(game, id, amount)
	if got > 0:
		game.message("Comprou %d × %s." % [got, name], 2)
		game.sound.play_at("loot", game.player.global_position, 0.5)
	elif not game.shop_stock.has(id):
		game.message("Acabou.", 2)
	elif game.inventory.count("coin") < ShopSystem.buy_price(game.floor, id):
		game.message("Faltam vinténs.", 2)
	else:
		game.message("Não cabe na mochila.", 2)
	refresh()

func sell(id: String, amount: int) -> void:
	if id == "":
		return
	var name: String = str(Items.info(id).get("name", id))
	var price: int = ShopSystem.sell_price(id)
	var gone: int = ShopSystem.sell(game, id, amount)
	if gone > 0:
		game.message("Vendeu %d × %s por %s." % [gone, name, coins(gone * price)], 2)
		game.sound.play_at("loot", game.player.global_position, 0.5)
	elif price <= 0:
		game.message("O mercador não compra isso.", 2)
	else:
		game.message("Guarde ou tire antes de vender.", 2)
	refresh()
