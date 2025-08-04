import requests
from bs4 import BeautifulSoup
import time

BASE_URL = "https://www.wowhead.com/mop-classic"
NPC_URL = f"{BASE_URL}/npc=64395/nam-ironpaw"
HEADERS = {'User-Agent': 'Mozilla/5.0'}

def get_vendor_sacks():
    print("Fetching vendor page...")
    resp = requests.get(NPC_URL, headers=HEADERS)
    soup = BeautifulSoup(resp.text, 'html.parser')

    # Extract all item links from the vendor list
    links = soup.select('a[href*="/item="]')
    seen = set()
    sacks = []
    print(links)
    print(f"Found {len(links)} links on the vendor page.")
    for link in links:
        href = link.get('href', '')
        if "/item=" in href and "sack-of" in link.text.lower():
            item_id = int(href.split("/item=")[-1].split("/")[0])
            name = link.text.strip()
            if item_id not in seen:
                seen.add(item_id)
                sacks.append({'name': name, 'item_id': item_id})
    
    print(f"Found {len(sacks)} sack items.")
    return sacks

def get_contained_material(sack_id):
    url = f"{BASE_URL}/item={sack_id}"
    print(f"Fetching sack {sack_id} contents...")
    resp = requests.get(url, headers=HEADERS)
    soup = BeautifulSoup(resp.text, 'html.parser')

    # Look in JSON blob for "contains" block
    script_tags = soup.find_all("script")
    for script in script_tags:
        if "new Listview({" in script.text and '"id":' in script.text and '"note":"Contains"' in script.text:
            lines = script.text.splitlines()
            for line in lines:
                if '"id":' in line and '"name"' in line:
                    try:
                        material_id = int(line.split('"id":')[1].split(",")[0])
                        material_name = line.split('"name":')[1].split('"')[1]
                        return material_id, material_name
                    except Exception:
                        continue
    return None, None

def build_inventory():
    sacks = get_vendor_sacks()
    inventory = {}

    for sack in sacks:
        sack_id = sack['item_id']
        sack_name = sack['name']
        material_id, material_name = get_contained_material(sack_id)
        time.sleep(1)  # Respectful delay for Wowhead

        if not material_id:
            print(f"❌ Failed to find contents for {sack_name} ({sack_id})")
            continue

        inventory[sack_id] = {
            'name': sack_name,
            'tokens': 1,
            'category': 'Unknown',
            'stack': 1,
            'contains': 5,
            'materialID': material_id,
            'materialName': material_name
        }

    return inventory

if __name__ == "__main__":
    data = build_inventory()
    print("\n✅ Final Ironpaw Inventory (Sacks only):\n")
    for k, v in data.items():
        print(f"[{k}] = {{ name = \"{v['name']}\", tokens = 1, category = \"{v['category']}\", stack = 1, contains = 5, materialID = {v['materialID']} }}, -- {v['materialName']}")
