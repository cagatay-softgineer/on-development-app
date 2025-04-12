from cmd_gui_kit import CmdGUI
import traceback
from util.logit import get_logger
import os

# Initialize CmdGUI for visual feedback
gui = CmdGUI()

logger = get_logger("logs/error.log", "Error")


def log_error(e):
    """
    Logs an error in the custom format:
    module_name.method_name1 <--- module_name.method_name2 <--- ... <--- | Error : e

    Parameters:
    e (Exception): The exception object that contains the error information.

    Returns:
    None
    """
    # Extract the traceback from the exception
    tb = traceback.extract_tb(e.__traceback__)

    # Build up module_name.method_name for each frame
    method_names = []
    for frame in tb:
        # frame.filename is the absolute or relative path (e.g.
        # /path/to/my_script.py)
        base_name = os.path.basename(frame.filename)  # e.g. "my_script.py"
        module_name = os.path.splitext(base_name)[0]  # e.g. "my_script"

        # Combine module and function/method name
        method_names.append(f"{module_name}.{frame.name}")

    # Join the module/method pairs with " <--- "
    chain = " <--- ".join(method_names)

    # Append the error type and message
    # e.g. "module.func <--- | Error : RuntimeError: Something went wrong!"
    chain += f"\n{type(e).__name__}: {str(e)}"
    gui.log(chain, level="error")
    logger.error(chain)
