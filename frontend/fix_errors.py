import os
import re

lib_dir = 'D:/fieldtrack/frontend/lib'
import_statement = "import 'package:fieldtrack/core/network/error_handler.dart';\n"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find catch variables e.g. catch (e) or catch(err)
    # This regex looks for catch blocks and captures the variable name
    catch_pattern = r'catch\s*\(\s*([a-zA-Z0-9_]+)\s*\)'
    
    modified = False
    new_content = content
    
    for match in re.finditer(catch_pattern, content):
        var_name = match.group(1)
        # Search for var_name.toString()
        target = f'{var_name}.toString()'
        replacement = f'ErrorHandler.getFriendlyErrorMessage({var_name})'
        
        if target in new_content:
            new_content = new_content.replace(target, replacement)
            modified = True
            
        # Also handle '$e' or '${e}' inside strings if they are used as error messages
        # E.g. throw Exception('Failed: $e');
        # Actually replacing e.toString() covers 90% of cases.
        # Let's also check for _error = e.toString() or similar which we just fixed.
    
    # Specific case for DioException assignments that might not use toString explicitly
    # E.g. _error = e; where e is DioException.
    
    if modified:
        if 'error_handler.dart' not in new_content:
            # Add import
            last_import = new_content.rfind('import ')
            if last_import != -1:
                end_of_line = new_content.find('\n', last_import)
                if end_of_line != -1:
                    new_content = new_content[:end_of_line+1] + import_statement + new_content[end_of_line+1:]
            else:
                new_content = import_statement + new_content
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

print("Done scanning and replacing.")
