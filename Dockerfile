FROM mcr.microsoft.com/powershell:latest

RUN apt-get update \ 
    && apt-get install -y git curl \ 
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \ 
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \ 
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \ 
    && apt-get update \ 
    && apt-get install -y gh \ 
    && apt-get clean \ 
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

ENTRYPOINT ["pwsh", "./kicker-bootstrap.ps1"]
CMD []
