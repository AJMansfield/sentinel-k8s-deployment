
from virusalert.config import Config
from virusalert.alerter import Alerter

import logging
from time import sleep
from datetime import datetime, timedelta
import contextlib
import os
# import urllib3

@contextlib.contextmanager
def pushd(path: str | os.PathLike):
    cwd = os.getcwd()
    os.chdir(path)
    yield
    os.chdir(cwd)

def loadConfig():
    with pushd('/etc/virusalert'):
        return Config()
    
def clamp(x, lower, upper):
    return min(max(x,lower), upper)

    
def main():
    logging.basicConfig(level=logging.INFO)
    # logging.getLogger('elasticsearch').setLevel(logging.WARNING)
    # urllib3.disable_warnings()
    # logging.getLogger('urllib3.connectionpool').setLevel(logging.WARNING)

    alerter = Alerter(config=loadConfig())
    
    while True:
        alerter.updateConfig(loadConfig())
        sleep_until = alerter.loop()
        sleep_len = clamp((sleep_until - datetime.now()), timedelta(seconds=0.1), timedelta(seconds=10))
        logging.info(f"Sleeping for {sleep_len} (can sleep until {sleep_until}).")
        sleep(sleep_len.total_seconds())

if __name__ == "__main__":
    main()