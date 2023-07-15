"""
Redis database schema definition and helpers for "Really Efficient" mode.
"""
import os
from typing import TypedDict

import redis.asyncio as redis


def redisKeyOf(str_SeriesInstanceUID: str) -> str:
    """Produce the redis key for a series."""
    return f'series:{str_SeriesInstanceUID}'


class ReData(TypedDict):
    """
    Series pull progress information.
    """
    NumberOfSeriesRelatedInstances: int
    """Number of DICOM files in the series, reported by px-find (findscu)"""
    fileCounter: int
    """Number of files received by storescp, incremented by px-recount"""
    lastUpdate: str
    """Timestamp in ISO8901 format."""


async def getRedisClient() -> redis.Redis:
    """
    Create the redis client.
    """
    if (url := os.getenv('PYPX_REDIS_URL', None)) is None:
        return redis.Redis(decode_responses=True)
    return await redis.from_url(url)
