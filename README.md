# nvim-config
A personal, fully customized Neovim configuration, tailored for an efficient and enhanced coding experience. This setup is built on NvChad, combining robust plugin management and a polished UI to optimize your workflow.

## Features
Plugin Management: Powered by NvChad’s modular structure and Packer for plugin organization.
Custom Mappings: Key mappings to streamline navigation, editing, and project management.
Optimized for Coding: Preconfigured with language servers, autocompletion, and syntax highlighting.
UI Enhancements: Sleek UI adjustments to improve readability and interface consistency.
## Installation
### Windows
If you're using Command Prompt (CMD):

```
git clone https://github.com/akshay-na/nvim-config %USERPROFILE%\AppData\Local\nvim && nvim
```

If you're using PowerShell (pwsh):

```
git clone https://github.com/akshay-na/nvim-config $ENV:USERPROFILE\AppData\Local\nvim && nvim
```

### Linux/Mac
```
git clone https://github.com/akshay-na/nvim-config ~/.config/nvim && nvim
```

## Usage
- **Launching Neovim:** Simply open Neovim by running nvim in your terminal.
- **Key Mappings:** Check the mappings.lua file for custom key bindings that enhance navigation and editing.
- **Plugin Configuration:** Refer to the `plugins/` folder for plugin-specific configurations.

## Customization
This configuration is modular, allowing for easy customization. Adjust settings in:

`init.lua` for core configurations.
`lua/custom/` for personal tweaks and overrides.

## Contributing
Feel free to fork this repository, add your own configurations, and open pull requests if you think others might benefit from your changes!
