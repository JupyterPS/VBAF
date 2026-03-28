import pandas as pd

# Load sales data
data = pd.read_csv('Company_SalesData.csv')  # Replace with actual path
data['Date'] = pd.to_datetime(data['Date'])  # Convert dates to datetime objects

# Example preprocessing: Extracting useful features
data['Year'] = data['Date'].dt.year
data['Month'] = data['Date'].dt.month
data['Day'] = data['Date'].dt.day

print(data.head())  # Check data structure

# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanySalesdataPreparing.py


