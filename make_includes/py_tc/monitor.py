from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Dict

import cocotb
from cocotb.queue import Queue

from transfer import TransferRecord

T = TypeVar("T", bound=TransferRecord)

class Monitor(ABC, Generic[T]):
    # Need pointer to determine concreate type
    _record_type: type[T]

    def __init__(self):
        self._queue: "Queue[T]" = Queue()
        self._coro: object = None
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
            transfer = await self.receive_transfer()
            await self._queue.put(transfer)

    @abstractmethod
    def _map_signals(self) -> None: ...

    @abstractmethod
    def receive_transfer(self) -> "T": ...

    async def receive(self) -> bytearray:
        transfers = []

        while True:
            transfer = await self._queue.get()
            transfers.append(transfer)

            if transfer.last():
                break

        data = self._record_type.to_bytes(transfers)
        return data
