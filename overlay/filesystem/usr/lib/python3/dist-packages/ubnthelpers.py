#!/usr/bin/python3
import os
from functools import lru_cache

"""
A handful of Ubiquiti Unifi device specific functions
"""

@lru_cache(None)
def get_ubnt_shortname() -> str:
    return os.popen("ubnteeprom -systeminfo -key shortname").read().rstrip("\n")
