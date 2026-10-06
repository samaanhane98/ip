from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Dict, TypeAlias, Any

import cocotb
from cocotb.queue import Queue

from transfer import TransferRecord

T = TypeVar("T", bound=TransferRecord)
Meta: TypeAlias = dict[str, Any] | bytearray

class Driver(ABC, Generic[T]):
    _transfer_type: type[T]

    def __init__(self):
        self._queue: "Queue[T]" = Queue()
        self._coro: cocotb.Task | None = None
        self._signals: Dict[str, object] = {}

    def start(self) -> None:
        if self._coro is not None:
            raise RuntimeError("Driver already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._coro is None:
            raise RuntimeError("Driver never started")
        self._coro.cancel()
        self._coro = None

    async def _run(self) -> None:
        while True:
            transfer = await self._queue.get()
            await self.transfer(transfer)

    @abstractmethod
    def _map_signals(self) -> None: ...

    @abstractmethod
    async def transfer(self, transfer: T) -> None: ...

    @abstractmethod
    async def send_transfer(self, transfer: T) -> None: ...

    @abstractmethod
    async def send(self, data: bytearray, meta: Meta | None = None): ...