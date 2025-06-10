# ISO Customization Tools

The `iso_tools` directory contains scripts for building automated installation media.

- **Customize-ISO.ps1** – Mounts a Windows ISO, injects a `bootstrap.ps1` script and an answer file, then rebuilds a bootable ISO using the Windows ADK.
- **bootstrap.ps1** – Downloads `kicker-bootstrap.ps1` from this repository and runs it. Used inside customized ISOs.
- **autounattend - generic.xml** – Example unattended installation file for Windows Server.
- **headlessunattend.xml** – Sample answer file for fully headless deployments.

These resources can be adapted to streamline automated lab setups.
