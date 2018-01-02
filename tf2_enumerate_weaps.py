import vdf

d = vdf.load(open('items_game.txt'))

def convert_name(name):
	name = name.replace(' ', '_')
	name = name.replace('-', '')
	name = name.replace('\'', '')
	name = name.replace('.', '')
	name = name.replace('!', '')

	return name

items = []

for item_name in d['items_game']['items']:
	item = d['items_game']['items'][item_name]

	try:
		item_index = int(item_name)
		if 'name' in item:
			if 'prefab' in item:
				if ('weapon_' in item['prefab'] or 'paintkit_base' in item['prefab']) and not 'paintkit' in item['prefab'] and not 'case' in item['prefab']:
					if 'defindex' in item:
						item_index = int(item['defindex'])
					items.append({'proper_name': item['name'], 'class_name': convert_name(item['name']), 'index': item_index})
			else:
				if 'item_class' in item and (item['item_class'] == 'tool' or item['item_class'] == 'bundle' or item['item_class'] == 'class_token' or item['item_class'] == 'slot_token' or item['item_class'] == 'supply_crate' or item['item_class'] == 'craft_item'):
					pass
				elif 'item_slot' in item and (item['item_slot'] == 'misc' or item['item_slot'] == 'action' or item['item_slot'] == 'taunt'):
					pass
				else:
					if 'defindex' in item:
						item_index = int(item['defindex'])
					items.append({'proper_name': item['name'], 'class_name': convert_name(item['name']), 'index': item_index})

	except ValueError:
		pass

for item in items:
	print(item['class_name'] + ' = ' + str(item['index']) + ' // ' + item['proper_name'])
