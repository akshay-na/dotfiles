# Userscripts

A collection of browser userscripts for various websites and automation tasks.

## Prerequisites

To use these userscripts, you need a userscript manager browser extension:

- **Tampermonkey** (recommended): [Chrome](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo) | [Firefox](https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/) | [Safari](https://apps.apple.com/us/app/tampermonkey/id1482490089)
- **Violentmonkey**: [Chrome](https://chrome.google.com/webstore/detail/violentmonkey/jinjaccalgkegednnccohejagnlnfdag) | [Firefox](https://addons.mozilla.org/en-US/firefox/addon/violentmonkey/)

## Installation Methods

### Method 1: Install All Scripts at Once (Recommended)

Use the bootstrap installer to automatically install all scripts from the manifest:

1. Install a userscript manager (Tampermonkey or Violentmonkey)
2. Install the bootstrap script:
   - Click [this link](https://raw.githubusercontent.com/akshay-na/dotfiles/main/userscripts/bootstrap.user.js) to open the bootstrap script
   - Your userscript manager should detect it and prompt you to install it
   - Click "Install" to add the bootstrap script
3. Run the bootstrap installer:
   - Navigate to any webpage
   - The bootstrap script will automatically fetch the manifest and open all script URLs in new tabs
   - Install each script as prompted by your userscript manager
   - You'll receive a notification showing how many scripts are being installed

**Note**: The bootstrap script opens each script URL in a new tab. You'll need to install each one individually, but this method ensures you get all scripts at once.

### Method 2: Install Individual Scripts

Install scripts one at a time by clicking their direct links:

- [Tomorrowland Queue Watcher](https://raw.githubusercontent.com/akshay-na/dotfiles/main/userscripts/scripts/tomorrowland-queue-watcher.user.js) - Notifies when queue redirects or changes state
- [Tomorrowland Auto Enter Shop](https://raw.githubusercontent.com/akshay-na/dotfiles/main/userscripts/scripts/tomorrowland-autoenter-shop.user.js) - Automatically clicks the "Enter Shop" button when available

## Available Scripts

### Tomorrowland Queue Watcher

- **Description**: Monitors the Tomorrowland queue page and sends desktop notifications when you're redirected or the queue state changes
- **Runs on**: `https://queue.prod.tomorrowland.com/*`
- **Features**:
  - Detects redirects away from the queue page
  - Monitors history changes (pushState/replaceState)
  - Polling fallback for hard redirects
  - Desktop notifications with click-to-focus

### Tomorrowland Auto Enter Shop

- **Description**: Automatically clicks the "Enter Shop" button on Tomorrowland event pages when it becomes available
- **Runs on**: `https://my.tomorrowland.com/event/*`
- **Features**:
  - Watches for button availability using MutationObserver
  - Only clicks when button is enabled
  - Runs at document-start for faster detection

## Directory Structure

```
userscripts/
├── README.md                    # This file
├── manifest.json                # List of all available scripts
├── bootstrap.user.js            # One-click installer for all scripts
└── scripts/
    ├── tomorrowland-queue-watcher.user.js
    └── tomorrowland-autoenter-shop.js
```

## Adding New Scripts

To add a new script to the collection:

1. Create your script file in the `scripts/` directory
2. Add a userscript header with `@name`, `@match`, and other metadata
3. Update `manifest.json` to include your new script:
   ```json
   {
     "scripts": [
       {
         "name": "Your Script Name",
         "url": "https://raw.githubusercontent.com/akshay-na/dotfiles/main/userscripts/scripts/your-script.user.js"
       }
     ]
   }
   ```
4. The bootstrap installer will automatically pick up the new script

## Updating Scripts

Scripts are automatically updated when you pull changes from the repository. However, your userscript manager may cache the scripts. To update:

1. Open your userscript manager dashboard
2. Find the script you want to update
3. Click "Check for updates" or manually reinstall from the script URL

## Troubleshooting

- **Scripts not installing**: Make sure you have a userscript manager installed and enabled
- **Bootstrap not working**: Check browser console for errors. Ensure you have `GM_xmlhttpRequest` permission enabled
- **Scripts not running**: Verify the `@match` patterns in the script header match the URLs you're visiting
- **Notifications not showing**: Check browser notification permissions for your userscript manager

## License

These scripts are part of my personal dotfiles repository. Use at your own risk.
