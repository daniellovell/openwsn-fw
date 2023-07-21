import matplotlib.pyplot as plt

# Read the data from the file
with open('data.txt', 'r') as f:
    data = [float(line) for line in f]

# Create a new figure
fig, ax = plt.subplots()

# Plot the data
ax.plot(data)

# Set the title and labels
ax.set_title('UART-Transmitted ADC Data')
ax.set_xlabel('Index')
ax.set_ylabel('Value')

# Add a grid
ax.grid(True)

# Enable minor grid lines
ax.minorticks_on()
ax.grid(which='minor', linestyle=':', linewidth='0.5', color='black')

# Set the plot style
plt.style.use('seaborn-darkgrid')

# Show the plot
plt.show()