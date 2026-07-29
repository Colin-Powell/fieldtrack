import re

with open('d:/fieldtrack/frontend/lib/features/supervisor/authentication/supervisor_login_screen.dart', 'r') as f:
    content = f.read()

old = '''                  // --- Back Arrow ---
IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        //'''

new = '''                  // --- Back Arrow (stays within supervisor portal) ---
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/supervisor/login');
                      }
                    },
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      size: 28,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),'''

if old in content:
    content = content.replace(old, new)
    with open('d:/fieldtrack/frontend/lib/features/supervisor/authentication/supervisor_login_screen.dart', 'w') as f:
        f.write(content)
    print('SUCCESS: File fixed')
else:
    print('ERROR: Could not find the exact string to replace')
    # Debug: find where the content differs
    idx = content.find('// --- Back Arrow ---')
    if idx >= 0:
        snippet = content[idx:idx+200]
        print(f'Found at index {idx}')
        print(f'Snippet: {repr(snippet)}')
    else:
        print('String not found at all')
