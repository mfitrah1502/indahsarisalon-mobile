import glob
import os

files = glob.glob('lib/pages/*.dart')

import_str = "import 'manage_services_page.dart';\n"
block_old = """        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
            (route) => false,
          );
        } else {"""

block_new = """        } else if (index == 4) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ManageServicesPage()),
            (route) => false,
          );
        } else {"""

for file in files:
    if "manage_services_page.dart" in file: continue
    
    with open(file, 'r') as f:
        content = f.read()
        
    if "import 'manage_services_page.dart';" not in content and "bottomNavigationBar:" in content:
        # Insert import after the last import
        lines = content.split('\n')
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith("import "):
                last_import = i
        lines.insert(last_import + 1, "import 'manage_services_page.dart';")
        content = '\n'.join(lines)
        
        # Replace the navigation block
        content = content.replace(block_old, block_new)
        
        with open(file, 'w') as f:
            f.write(content)
        print(f"Updated {file}")

