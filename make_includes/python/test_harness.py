from abc import ABC, abstractmethod
from functools import wraps

def test(func):
    func._is_test = True
    return func

class TestHarness(ABC):
    def __init__(self, dut):
        self.dut = dut

    @abstractmethod
    async def reset_tc(self, cycles = 10):
        pass

    async def run_tests(self):
        for name in dir(self):
            method = getattr(self, name)
            if callable(method) and getattr(method, "_is_test", False):
                print(f"Running test: {name}")
                await self.reset_tc()
                await method()

