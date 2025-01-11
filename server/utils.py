import pyodbc
import logging
from dotenv import load_dotenv
import os
from error_handling import log_error
from cmd_gui_kit import CmdGUI

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

# Logging setup
LOG_DIR = "logs/utils.log"
logger = logging.getLogger("Utils")
logger.setLevel(logging.DEBUG)

# Create file handler
file_handler = logging.FileHandler(LOG_DIR, encoding="utf-8")
file_handler.setLevel(logging.DEBUG)

# Create console handler
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)

# Create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)

# Add handlers to the logger
logger.addHandler(file_handler)
logger.addHandler(console_handler)

logger.propagate = False

load_dotenv()

PRIMARY_SQL_SERVER = os.getenv("SQL_SERVER_HOST")
PRIMARY_SQL_SERVER_PORT = os.getenv("SQL_SERVER_PORT")
PRIMARY_SQL_DATABASE = os.getenv("SQL_SERVER_DATABASE")
PRIMARY_SQL_USER = os.getenv("SQL_SERVER_USER")
PRIMARY_SQL_PASSWORD = os.getenv("SQL_SERVER_PASSWORD")

SECONDARY_SQL_DATABASE = os.getenv("SSQL_SERVER_DATABASE")

# Store connection strings in a dictionary
DB_CONNECTION_STRINGS = {
    "primary": f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={PRIMARY_SQL_SERVER},{PRIMARY_SQL_SERVER_PORT};DATABASE={PRIMARY_SQL_DATABASE};UID={PRIMARY_SQL_USER};PWD={PRIMARY_SQL_PASSWORD}",
    "secondary": f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={PRIMARY_SQL_SERVER},{PRIMARY_SQL_SERVER_PORT};DATABASE={SECONDARY_SQL_DATABASE};UID={PRIMARY_SQL_USER};PWD={PRIMARY_SQL_PASSWORD}",
}

def get_db_connection(db_name):
    """Get a connection to the specified database."""
    if db_name not in DB_CONNECTION_STRINGS:
        raise log_error(ValueError(f"Unknown database name: {db_name}"))

    try:
        conn = pyodbc.connect(DB_CONNECTION_STRINGS[db_name])
        logger.info(f"Connected to {db_name} database successfully.")
        return conn
    except pyodbc.Error as e:
        gui.log(f"Database connection failed: {e}", level="error")
        logger.error(f"Database connection failed: {e}")
        raise log_error(pyodbc.Error("Database connection failed !"))

def execute_query_with_logging(query, db_name, params=(), fetch=False):
    """
    Executes a query on the specified database with logging and visual feedback.
    """
    conn = None
    try:
        gui.status(f"Connecting to {db_name} database...", status="info")
        conn = get_db_connection(db_name)
        cursor = conn.cursor()

        # Log and display query execution
        gui.log(f"Executing query: {query}", level="info")
        logger.info(f"Executing query: {query}")

        # Ensure params are in the correct format if using TVP
        if isinstance(params, tuple) and len(params) == 1 and isinstance(params[0], (tuple, list)):
            params = params[0]  # Unwrap the sequence if necessary

        cursor.execute(query, params)

        if fetch:
            rows = cursor.fetchall()
            gui.status("Query executed successfully, fetching results...", status="success")
            logger.info(f"Query succeeded. Columns: {[column[0] for column in cursor.description]}")
            return rows, cursor.description

        conn.commit()
        gui.status("Query executed successfully and committed.", status="success")
        logger.info("Query executed successfully and committed.")
        return None
    except pyodbc.Error as e:
        gui.status(f"Query execution failed: {e}", status="error")
        logger.error(f"Query execution error: {e}")
        log_error(e)
        raise
    finally:
        if conn:
            conn.close()
            gui.status(f"Connection to {db_name} database closed.", status="info")