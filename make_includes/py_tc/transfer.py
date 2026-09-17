from abc import ABC, abstractmethod
from typing import Self

class TransferRecord(ABC):
    @abstractmethod
    def from_bytes(self, data: bytearray) -> list[Self]: ...

    @abstractmethod
    def to_bytes(self, data: list[Self]) -> bytearray: ...

    @abstractmethod
    def last(self) -> bool: ...