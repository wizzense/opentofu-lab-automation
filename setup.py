"""Setup file for OpenTofu Lab Automation Python package."""

from setuptools import setup, find_packages

setup(
    name="opentofu-lab-automation",
    version="1.0.0",
    description="OpenTofu Lab Automation Tools",
    packages=find_packages(),
    python_requires=">=3.8",
    install_requires=[
        "pytest>=7.0.0",
        "pytest-cov>=4.0.0",
        "pyyaml>=6.0",
        "click>=8.0.0",
    ],
    extras_require={
        "dev": [
            "black>=22.0.0",
            "flake8>=5.0.0",
            "isort>=5.0.0",
        ]
    },
    entry_points={
        "console_scripts": [
            "labctl=py.labctl.cli:main",
        ],
    },
    author="OpenTofu Lab Team",
    author_email="team@opentofu-lab.com",
    url="https://github.com/wizzense/opentofu-lab-automation",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
    ],
)
