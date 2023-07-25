import serial
import re
import time

# Open the serial port
ser = serial.Serial('COM17', baudrate=1000000)  # replace 'COM1' with your COM port

try:
    with open('data.txt', 'w') as f:
        last_print_time = time.time()
        while True:
            # Read a line from the serial port
            line = ser.readline().decode('utf-8')

            # Remove NUL characters
            line = line.replace('\0', '')

            # Split the line into words using space or newline as the separator
            words = re.split(r'[\s\n]+', line)

            # Remove any empty strings resulting from the split operation
            words = [word for word in words if word]

            # Save the cleaned-up words to the file
            for word in words:
                f.write(word + '\n')
            # Print a message every 0.1s to indicate that data is being received
            if time.time() - last_print_time >= 1:
                print('Receiving data...')
                last_print_time = time.time()

except KeyboardInterrupt:
    # Close the serial port when the script is terminated with Ctrl+C
    ser.close()
