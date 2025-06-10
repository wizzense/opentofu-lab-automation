import os
from azure.ai.inference import ChatCompletionsClient
from azure.core.credentials import AzureKeyCredential


def invoke_model(model: str, prompt: str, parameters: dict | None = None) -> str:
    """Call GitHub Models using the Azure AI Inference SDK."""
    token = os.getenv("GITHUB_MODEL_TOKEN")
    if not token:
        raise RuntimeError("GITHUB_MODEL_TOKEN not set")

    client = ChatCompletionsClient(
        endpoint="https://api.github.com/ai",
        credential=AzureKeyCredential(token),
    )

    params = parameters or {}
    result = client.complete(messages=[{"role": "user", "content": prompt}], model=model, **params)
    return result.choices[0].message.content
