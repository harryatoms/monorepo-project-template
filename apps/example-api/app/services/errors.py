"""Domain-neutral application errors translated by the API layer."""


class ApplicationError(Exception):
    """Base class for expected application failures."""


class ProviderUnavailableError(ApplicationError):
    """Raised when an optional upstream provider cannot complete a request."""


class InvalidProviderResponseError(ApplicationError):
    """Raised when an optional provider response violates the expected contract."""


class ConfigurationError(ApplicationError):
    """Raised when optional provider configuration is incomplete or invalid."""
