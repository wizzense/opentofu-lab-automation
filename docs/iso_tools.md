# ISO Customization Tools

The `tools/iso` directory contains scripts for building automated installation media.

- **Customize-ISO.ps1** – Mounts a Windows ISO, injects a `bootstrap.ps1` script and an answer file, then rebuilds a bootable ISO using the Windows ADK.
- **bootstrap.ps1** – Downloads `pwsh/kicker-bootstrap.ps1` from this repository and runs it. Used inside customized ISOs.
- **autounattend - generic.xml** – Example unattended installation file for Windows Server.
- **headlessunattend.xml** – Sample answer file for fully headless deployments.
- **kickstart.cfg** – Example Kickstart file for automating Linux installations.
- **kickstart-bootstrap.sh** – Shell helper that downloads `kickstart.cfg` and launches a sample `virt-install` command.

These resources can be adapted to streamline automated lab setups.
