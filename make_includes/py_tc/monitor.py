from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Dict, TypeAlias, Any, Tuple

import cocotb
from cocotb.queue import Queue

from transfer import TransferRecord

T = TypeVar("T", bound=TransferRecord)
Meta: TypeAlias = dict[str, Any] | bytearray | None

class Monitor(ABC, Generic[T]):
    _record_type: type[T]

    def __init__(self):
        self._queue: "Queue[T]" = Queue()
        self._coro: cocotb.Task | None = None
        self._signals: Dict[str, object] = {}

    def start(self) -> None:
        if self._coro is not None:
            raise RuntimeError("Sink already started")
        self._coro = cocotb.start_soon(self._run())

    def stop(self) -> None:
        if self._coro is None:
            raise RuntimeError("Sink never started")
        self._coro.cancel()
        self._coro = None

    async def _run(self) -> None:
        while True:
            transfer = await self.transfer()
            await self._queue.put(transfer)

    @abstractmethod
    def _map_signals(self) -> None: ...

    @abstractmethod
    def transfer(self) -> T: ...

    @abstractmethod
    def receive_transfer(self) -> T: ...

    @abstractmethod
    async def receive(self) -> Tuple[bytearray, Meta | None]: ...