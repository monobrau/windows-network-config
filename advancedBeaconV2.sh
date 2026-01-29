#!/bin/bash

# Advanced PowerShell Obfuscator
# Multi-layer obfuscation script

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input.ps1> <output.ps1>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
    echo "[!] Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

echo "] Advanced PowerShell Obfuscator"
echo "[*] Input:  $INPUT_FILE"
echo "[*] Output: $OUTPUT_FILE"
echo ""

# Copy input to first layer
cp "$INPUT_FILE" "$TMP_DIR/layer0.ps1"
CURRENT_LAYER="$TMP_DIR/layer0.ps1"

# Layer 1: Renaming objects
echo "[*] Layer 1: Renaming objects..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer1.ps1" << 'PYTHON_EOF'
import re
import random
import string
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

var_pattern = r'\$([a-zA-Z_][a-zA-Z0-9_]*)'
variables = set(re.findall(var_pattern, content))

var_replacements = {}
for var in variables:
    if len(var) > 3:
        new_name = ''.join(random.choices(string.ascii_letters, k=random.randint(8, 15)))
        var_replacements[var] = new_name

for old_var, new_var in var_replacements.items():
    content = re.sub(r'\$' + re.escape(old_var) + r'\b', f'${new_var}', content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer1.ps1"

# Layer 2: Obfuscating boolean values
echo "[*] Layer 2: Obfuscating boolean values..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer2.ps1" << 'PYTHON_EOF'
import re
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

content = re.sub(r'\$true\b', '[bool]1', content)
content = re.sub(r'\$false\b', '[bool]0', content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer2.ps1"

# Layer 3: Applying cmdlet quote interruption
echo "[*] Layer 3: Applying cmdlet quote interruption..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer3.ps1" << 'PYTHON_EOF'
import re
import random
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

def interrupt_cmdlet(match):
    cmdlet = match.group(0)
    if random.random() < 0.3:
        parts = cmdlet.split('-')
        if len(parts) == 2:
            return f"{parts[0]}'-'{parts[1]}"
    return cmdlet

pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, interrupt_cmdlet, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer3.ps1"

# Layer 4: Applying cmdlet caret interruption
echo "[*] Layer 4: Applying cmdlet caret interruption..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer4.ps1" << 'PYTHON_EOF'
import re
import random
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

def caret_interrupt(match):
    cmdlet = match.group(0)
    if random.random() < 0.2:
        return cmdlet.replace('-', '^-')
    return cmdlet

pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, caret_interrupt, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer4.ps1"

# Layer 5: Applying Get-Command technique
echo "[*] Layer 5: Applying Get-Command technique..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer5.ps1" << 'PYTHON_EOF'
import re
import random
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

cmdlet_replacements = {
    'Get-Content': "(Get-Command 'Get-Content').Name",
    'Set-Content': "(Get-Command 'Set-Content').Name",
    'Invoke-Expression': "(Get-Command 'Invoke-Expression').Name",
    'Write-Host': "(Get-Command 'Write-Host').Name",
}

def replace_with_getcommand(match):
    cmdlet = match.group(0)
    if cmdlet in cmdlet_replacements and random.random() < 0.3:
        return cmdlet_replacements[cmdlet]
    return cmdlet

pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, replace_with_getcommand, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer5.ps1"

# Layer 6: Substituting loops
echo "[*] Layer 6: Substituting loops..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer6.ps1" << 'PYTHON_EOF'
import re
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

content = re.sub(r'\bforeach\s*\(', 'ForEach-Object { param(', content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer6.ps1"

# Layer 7: Substituting commands
echo "[*] Layer 7: Substituting commands..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer7.ps1" << 'PYTHON_EOF'
import re
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

replacements = {
    'gc': 'Get-Content',
    'sc': 'Set-Content',
    'iex': 'Invoke-Expression',
    'wh': 'Write-Host',
}

for alias, cmdlet in replacements.items():
    content = re.sub(r'\b' + re.escape(alias) + r'\b', cmdlet, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer7.ps1"

# Layer 8: String manipulation
echo "[*] Layer 8: String manipulation..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer8.ps1" << 'PYTHON_EOF'
import re
import random
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

def obfuscate_string(match):
    string_val = match.group(1)
    if len(string_val) > 5 and random.random() < 0.3:
        chars = [f"'{c}'" for c in string_val]
        return f"(-join @({','.join(chars)}))"
    return match.group(0)

content = re.sub(r"'([^']+)'", obfuscate_string, content)
content = re.sub(r'"([^"]+)"', obfuscate_string, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer8.ps1"

# Layer 9: Randomizing character cases
echo "[*] Layer 9: Randomizing character cases..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer9.ps1" << 'PYTHON_EOF'
import re
import random
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

def randomize_case(match):
    cmdlet = match.group(0)
    if random.random() < 0.4:
        return ''.join(c.lower() if random.random() < 0.5 else c.upper() for c in cmdlet)
    return cmdlet

pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, randomize_case, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer9.ps1"

# Layer 10: Manipulating comments
echo "[*] Layer 10: Manipulating comments..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer10.ps1" << 'PYTHON_EOF'
import re
import random
import string
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

def add_junk_to_comment(match):
    comment = match.group(0)
    junk = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(5, 15)))
    return comment.rstrip() + f" {junk}"

content = re.sub(r'#.*', add_junk_to_comment, content)

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer10.ps1"

# Layer 11: Appending junk code
echo "[*] Layer 11: Appending junk code..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer11.ps1" << 'PYTHON_EOF'
import random
import string
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

junk_functions = []
for _ in range(random.randint(2, 5)):
    func_name = ''.join(random.choices(string.ascii_letters, k=8))
    junk_functions.append(f"function Set-{func_name} {{ [Console]::Beep() }}")

junk_vars = []
for _ in range(random.randint(3, 7)):
    var_name = f"junk_{random.randint(1000, 9999)}"
    junk_vars.append(f"${var_name} = Get-Random")

junk_code = "\n".join(junk_functions) + "\n" + "\n".join(junk_vars) + "\n\n"
content = junk_code + content

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer11.ps1"

# Layer 12: Rearranging script components
echo "[*] Layer 12: Rearranging script components..."
cp "$CURRENT_LAYER" "$TMP_DIR/layer12.ps1"
CURRENT_LAYER="$TMP_DIR/layer12.ps1"

# Layer 13: Converting to line-by-line execution
echo "[*] Layer 13: Converting to line-by-line execution..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer13.ps1" << 'PYTHON_EOF'
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

lines = content.split('\n')
script_array = "$scriptLines = @(\n"
escaped_lines = []
for line in lines:
    if line.strip():
        escaped_line = line.replace('"', '`"').replace('$', '`$')
        escaped_lines.append(f'    "{escaped_line}"')
script_array += ",\n".join(escaped_lines)
script_array += "\n)\n\n"

executor = """foreach ($line in $scriptLines) {
    try {
        Invoke-Expression $line
    } catch {
        # Silent continue
    }
}
"""

content = script_array + executor

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer13.ps1"

# Layer 14: Adding detection triggers
echo "[*] Layer 14: Adding detection triggers..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer14.ps1" << 'PYTHON_EOF'
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

detection_code = """
$isVM = (Get-WmiObject Win32_ComputerSystem).Manufacturer -match 'VMware|VirtualBox|Xen|QEMU'
$isSandbox = (Get-Process | Where-Object {$_.ProcessName -match 'vbox|vmware|vmtoolsd'}) -ne $null
if ($isVM -or $isSandbox) {
    exit
}
"""

content = detection_code + "\n" + content

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer14.ps1"

# Layer 15: Increasing entropy
echo "[*] Layer 15: Increasing entropy..."
python3 - "$CURRENT_LAYER" "$TMP_DIR/layer15.ps1" << 'PYTHON_EOF'
import random
import string
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

entropy_vars = []
for _ in range(random.randint(10, 20)):
    var_name = ''.join(random.choices(string.ascii_letters, k=random.randint(8, 15)))
    var_value = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(10, 30)))
    entropy_vars.append(f"${var_name} = '{var_value}'")

entropy_block = "\n".join(entropy_vars) + "\n\n"
content = entropy_block + content

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(content)
PYTHON_EOF
CURRENT_LAYER="$TMP_DIR/layer15.ps1"

# Final Layer: Base64 encoding wrapper
echo "[*] Final Layer: Base64 encoding wrapper..."
python3 - "$CURRENT_LAYER" "$OUTPUT_FILE" << 'PYTHON_EOF'
import base64
import sys

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    script_content = f.read()

base64_content = base64.b64encode(script_content.encode('utf-8')).decode('utf-8')

wrapped_script = f"""$base64 = '{base64_content}'
$bytes = [System.Convert]::FromBase64String($base64)
$dec = [System.Text.Encoding]::UTF8.GetDecoder()
$scr = $dec.GetString($bytes)
Invoke-Expression $scr
"""

with open(sys.argv[2], 'w', encoding='utf-8') as f:
    f.write(wrapped_script)
PYTHON_EOF

# Get file sizes
ORIGINAL_SIZE=$(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE" 2>/dev/null || echo "0")
OBFUSCATED_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null || echo "0")

echo ""
echo "[+] Obfuscation complete!"
echo "[+] Original size: $ORIGINAL_SIZE bytes"
echo "[+] Obfuscated size: $OBFUSCATED_SIZE bytes"
echo ""
echo "[*] Test with: powershell.exe -ExecutionPolicy Bypass -File $OUTPUT_FILE"
