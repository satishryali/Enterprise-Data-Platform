import pandas as pd
from pathlib import Path
import configparser


BASE_DIR = Path(__file__).resolve().parent.parent
import sys
sys.insert(0,BASE_DIR /"logs"/'logger.py')
import logger

config_path = BASE_DIR / "config"
log.info("Config_path : %s" % config_path)
file_path = BASE_DIR / "data" / "input"
log.info("File_path : %s" % file_path)
config = configparser.ConfigParser()
config.read(filenames=config_path/"config.ini")
log.info(f"using pandas to read the csv file")
data = pd.read_csv(file_path/"employees.csv")
log.info(data)