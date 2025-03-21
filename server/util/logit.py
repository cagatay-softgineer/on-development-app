import logging

def check_log_folder(LOG_DIR: str = "logs") -> None:
    """
    This function checks if the logs directory exists. If it does not exist, it creates the directory.

    Parameters:
    LOG_DIR (str): The directory where log files will be stored. Default is "logs".

    Returns:
    None: This function does not return any value.
    """
    try:
        import os
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
    # Logging setup
    logger = logging.getLogger(logger_name)
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

    return logger
