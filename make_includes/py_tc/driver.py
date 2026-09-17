from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Dict

import cocotb
from cocotb.queue import Queue

from transfer import TransferRecord

T = TypeVar("T", bound=TransferRecord)

class Driver(ABC, Generic[T]):
    # Need pointer to determine concreate type
    _record_type: type[T]

    def __init__(self):
        self._queue: "Queue[T]" = Queue()
        self._coro: object = None
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
            await self.send_transfer(transfer)

    @abstractmethod
    def _map_signals(self) -> None: ...

    @abstractmethod
    def send_transfer(self, transfer: "T") -> None: ...

    async def send(self, transfers: list["T"]):
        for transfer in transfers:
            await self._queue.put(transfer)