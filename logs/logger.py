import logging

logging.basicConfig(filename = "applog.log", format = "%(asctime)s | %(level)s | %(message)s")

log = logging.getLogger()

log.setLevel(logging.DEBUG)


