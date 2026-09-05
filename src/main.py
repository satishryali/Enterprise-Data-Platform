import asyncio

async def task(name, delay):
    print(f"{name} started")
    await asyncio.sleep(delay)
    print(f"{name} finished after {delay}s")

async def main():
    await asyncio.gather(
        task("A", 3),
        task("B", 2),
        task("C", 1),
    )

asyncio.run(main())
