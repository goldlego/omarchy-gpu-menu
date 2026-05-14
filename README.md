Omarchy GPU Menu 🎮

A visually appealing, dynamically themed, Wofi-based GPU mode switcher for Linux (specifically built for the Omarchy OS).

Under the hood, it acts as a smart, safe wrapper for supergfxctl, handling VFIO bindings, sleep configurations, and hardware MUX switches natively through a beautiful graphical interface.

✨ Features

Dynamic Theming: Seamlessly inherits Omarchy's global Waybar GTK CSS. When your system theme changes, the menu changes with it.

Smart Switching Logic: Automatically handles VFIO enabling/disabling and system-sleep fixes based on your selected GPU mode before initiating a reboot.

Hardware MUX Aware: Prevents incompatible mode switching if the physical Asus MUX switch (AsusMuxDgpu) is engaged.

Polkit Integrated: Primes sudo/pkexec so you never get stuck with an invisible terminal password prompt.

Zero Clutter: A perfectly sized, centered Wofi window with no unnecessary scrollbars or text entry boxes.

📦 Dependencies

Before installing, ensure your system has the following packages:

supergfxctl (Make sure supergfxd is enabled via systemd)

wofi

libnotify

bash

pacman-contrib (Required for updpkgsums if building from source)

base-devel / git

🚀 Installation (Arch Linux / Omarchy)

The easiest way to install is by building the package using the included PKGBUILD.

Clone the repository:

git clone https://github.com/goldlego/omarchy-gpu-menu.git
cd omarchy-gpu-menu


Generate the security checksums:

updpkgsums


Build and install the package:

makepkg -si


💻 Usage

Once installed, you can launch the menu in a few ways:

Terminal: Simply run omarchy-gpu-menu.

App Launcher: Search for "GPU Mode Switcher" in your desktop environment's application menu.

Keybind: Map omarchy-gpu-menu to a custom keybind in your Hyprland/Sway config. For example, in hyprland.conf:

bind = $mainMod SHIFT, G, exec, omarchy-gpu-menu


Or if your keyboard has a dedicated button for armoury-crate or others for this:

```bash
bindd = ,XF86Launch3, Switch GPU, exec, omarchy-gpu-menu
```

🛠️ Configuration & Customization

If you want to tweak the size, layout, or fall-back colors, the configuration files are installed system-wide.

Layout & Geometry: /etc/omarchy/wofi/gpu-menu.conf

Styling & Colors: /etc/omarchy/wofi/gpu-style.css

(Note: If you run the script directly from the downloaded GitHub folder, it will prioritize the local ./config/ directory for easy development and testing).

📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
