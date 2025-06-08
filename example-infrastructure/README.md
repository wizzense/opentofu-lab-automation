This repository contains example OpenTofu configurations for deploying a small
Hyper-V lab.  The configuration now uses a reusable module to create virtual
machines so that additional operating systems can be added easily.

To use these configurations clone the repo and run the usual OpenTofu
workflow:

```
tofu init
tofu validate
tofu plan
tofu apply
```

If you need to reset your working copy run:

```
git reset --hard
git clean -fd
git pull
```

## Automated testing

A GitHub Actions workflow located at `.github/workflows/test.yml` installs
OpenTofu using the `wizzense/opentofu-lab-automation` action. The workflow
runs `tofu init` and `tofu validate` whenever the repository is pushed to or a
pull request is opened.

