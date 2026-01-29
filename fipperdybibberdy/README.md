# FIPPERD Award Nomination Generator

A Python GUI application for generating legitimate-sounding FIPPERD award nominations with randomized, organic content.

## What is FIPPERD?

FIPPERD stands for:
- **F**ocused on the client
- **I**nnovative  
- **P**ositive
- **P**recise
- **E**ngaged and communicative
- **R**esponsible and accountable
- **D**riven

## Features

- **GUI Interface**: Easy-to-use tkinter-based interface
- **Team & Client Management**: Dropdown selections with customizable teams and clients
- **Randomized Content**: Generates organic-sounding nominations with varied language
- **Settings Persistence**: Save and load your team/client configurations
- **Email-Ready Output**: Copy generated nominations directly to clipboard for email use
- **Category Selection**: Choose specific FIPPERD categories for targeted nominations

## Installation & Usage

1. **Clone or Download**: Save the `fipperd_nomination_generator.py` file to your desired location (e.g., `c:\dev\fipperd_generator\`)

2. **Run the Application**:
   ```bash
   python fipperd_nomination_generator.py
   ```

3. **First Time Setup**:
   - The app comes with default teams and clients
   - Use "Manage Teams/Clients" to customize your organization's structure
   - Click "Save Settings" to persist your changes

4. **Generate Nominations**:
   - Enter the employee name
   - Select their team
   - Choose the client
   - Pick a FIPPERD category
   - Click "Generate Nomination"
   - Copy the result to clipboard for use in emails

## Default Teams & Clients

The application comes pre-configured with sample teams and clients:

- **IT Support**: Key Technical, DataFlow Corp, SecureNet Solutions, TechVision Inc
- **Development**: InnovateTech, CodeCraft Solutions, DigitalForge, AppMasters
- **Infrastructure**: CloudFirst, NetworkPro, ServerTech, SystemCore
- **Security**: CyberGuard, SecureBase, ThreatShield, SafeNet Corp
- **Project Management**: DeliveryPro, ProjectFlow, TaskMaster, AgileWorks

## Requirements

- Python 3.x (tkinter included with standard Python installations)
- No additional packages required - uses only standard library modules

## Files

- `fipperd_nomination_generator.py` - Main application
- `fipperd_settings.json` - Auto-generated settings file (created on first save)
- `requirements.txt` - Dependencies documentation
- `README.md` - This documentation

## Example Output

> "Patrick identified a potential delay in a critical project that involved a LetsEncrypt certificate for Key Technical and developed an innovative contingency plan by purchasing a certificate instead. This ensured the project stayed on track and met the deadline for our client."

The generator creates varied, professional-sounding nominations that highlight different aspects of the FIPPERD values while maintaining authenticity and avoiding repetitive language patterns.
