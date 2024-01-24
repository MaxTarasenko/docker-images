#!/bin/sh

# Logging for debugging
echo "Running LibreOffice on port 8100"

# Running LibreOffice in command listening mode
soffice --minimized --nodefault --invisible --nologo --norestore --headless --nofirststartwizard --accept="socket,host=0.0.0.0,port=8100;urp;"
