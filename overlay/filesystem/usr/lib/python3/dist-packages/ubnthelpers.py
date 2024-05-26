#!/usr/bin/python3
from functools import lru_cache

"""
A handful of Ubiquiti Unifi device specific functions
"""

UBNTHAL_PATH = "/proc/ubnthal/system.info"


@lru_cache(None)
def get_ubnt_shortname() -> str:
    try:
        with open(UBNTHAL_PATH, "r") as f:
            ubnthal_model = [i for i in f.readlines() if i.startswith("shortname=")][0]
        return ubnthal_model.lstrip("shortname=").rstrip("\n")
    except FileNotFoundError:
        print(
            f"Error: unable to open {UBNTHAL_PATH}; is the ubnthal kernel module loaded?!"
        )
        raise
