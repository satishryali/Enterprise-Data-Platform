import logging

logging.basicConfig(
    filename="applog.log",
    format="%(asctime)s | %(levelname)s | %(message)s",
    level=logging.DEBUG
)

log = logging.getLogger(__name__)
