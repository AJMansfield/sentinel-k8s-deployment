
from virusalert.config import Config
from virusalert.alerter import Alerter

import logging
from time import sleep
from datetime import datetime, timedelta
import urllib3

def main():
    logging.basicConfig(level=logging.INFO)
    logging.getLogger('elasticsearch').setLevel(logging.WARNING)
    urllib3.disable_warnings()
    logging.getLogger('urllib3.connectionpool').setLevel(logging.WARNING)

    config = Config()
    alerter = Alerter(config=config)
    while True:
        sleep_until = alerter.loop()
        sleep_len = max(timedelta(seconds=0.1), (sleep_until - datetime.now()))
        logging.info(f"Sleeping for {sleep_len} (until {sleep_until}).")
        sleep(sleep_len.total_seconds())

if __name__ == "__main__":
    main()