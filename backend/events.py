"""Internal event bus for Levish backend."""
import asyncio
import inspect
import logging
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


class EventBus:
    """Async event bus with wildcard support."""

    def __init__(self) -> None:
        # Map event_name -> list of (callback, subscription_id)
        self._subscribers: Dict[str, List[Callable]] = {}
        self._lock = asyncio.Lock()

    async def subscribe(self, event_name: str, callback: Callable) -> str:
        """Subscribe an async callback to an event (or '*' for all events).

        Returns a subscription id that can be used to unsubscribe.
        """
        async with self._lock:
            if event_name not in self._subscribers:
                self._subscribers[event_name] = []
            self._subscribers[event_name].append(callback)
        sub_id = f"{event_name}:{id(callback)}"
        logger.debug("EventBus: subscribed %s to '%s'", sub_id, event_name)
        return sub_id

    async def unsubscribe(self, event_name: str, callback: Callable) -> None:
        """Remove a previously subscribed callback."""
        async with self._lock:
            if event_name in self._subscribers:
                try:
                    self._subscribers[event_name].remove(callback)
                except ValueError:
                    pass

    async def emit(self, event_name: str, data: Any = None) -> None:
        """Emit an event to all subscribers (specific + wildcard)."""
        async with self._lock:
            specific = list(self._subscribers.get(event_name, []))
            wildcard = list(self._subscribers.get("*", []))

        callbacks = specific + wildcard
        for cb in callbacks:
            try:
                if inspect.iscoroutinefunction(cb):
                    await cb(event_name, data)
                else:
                    cb(event_name, data)
            except Exception as exc:
                logger.error(
                    "EventBus: error in callback for event '%s': %s", event_name, exc
                )

    def subscribe_sync(self, event_name: str, callback: Callable) -> None:
        """Synchronous convenience wrapper for subscribe (non-async context)."""
        if event_name not in self._subscribers:
            self._subscribers[event_name] = []
        self._subscribers[event_name].append(callback)
