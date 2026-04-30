from __future__ import annotations

from typing import Protocol


class LLMClient(Protocol):
    """Small interface for optional text-generation providers."""

    async def complete(self, prompt: str) -> str:
        """Return a text completion for a prompt."""
