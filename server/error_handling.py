import logging
import os
from cmd_gui_kit import CmdGUI
import traceback

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

# Logging setup
LOG_DIR = "logs/error.log"
logger = logging.getLogger("Error")
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

def log_error(e):
    """
    Logs an error in the custom format:
      module_name.method_name1 <--- module_name.method_name2 <--- ... <--- | Error : e
    """
    # Extract the traceback from the exception
    tb = traceback.extract_tb(e.__traceback__)
    
    # Build up module_name.method_name for each frame
    method_names = []
    for frame in tb:
        # frame.filename is the absolute or relative path (e.g. /path/to/my_script.py)
        base_name = os.path.basename(frame.filename)    # e.g. "my_script.py"
        module_name = os.path.splitext(base_name)[0]    # e.g. "my_script"
        
        # Combine module and function/method name
        method_names.append(f"{module_name}.{frame.name}")
    
    # Join the module/method pairs with " <--- "
    chain = " <--- ".join(method_names)
    
    # Append the error type and message
    # e.g. "module.func <--- | Error : RuntimeError: Something went wrong!"
    chain += f"\n{type(e).__name__}: {str(e)}"
    gui.log(chain,level="error")
    logger.error(chain)
