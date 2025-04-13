import os
import logging


def check_log_folder(LOG_DIR: str = "logs") -> None:
    """
    This function checks if the logs directory exists. If it does not exist, it creates the directory.

    Parameters:
        LOG_DIR (str): The directory where log files will be stored. Default is "logs".

    Returns:
        None
    """
    try:
        # Ensure the logs directory exists; if not, create it
        if not os.path.exists(LOG_DIR):
            os.makedirs(LOG_DIR)
    except OSError:
        print("Unable to create logs directory")


def get_logger(LOG_DIR: str, logger_name: str) -> logging.Logger:
    """
    This function creates and configures a logger with file and console handlers.

    Parameters:
        LOG_DIR (str): The directory where log files will be stored.
        logger_name (str): The name of the logger.

    Returns:
        logging.Logger: The configured logger.
    """
    # Ensure the log directory exists.
    check_log_folder(LOG_DIR)

    # Create full path for the log file (e.g., logs/Utils.log).
    log_file_path = os.path.join(LOG_DIR, f"{logger_name}.log")

    # Logging setup
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)

    # Create file handler using the full file path.
    file_handler = logging.FileHandler(log_file_path, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)

    # Create console handler.
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)

    # Create formatter and add it to the handlers.
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    # Add handlers to the logger, but avoid adding duplicates.
    if not logger.handlers:
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)

    logger.propagate = False

    return logger
