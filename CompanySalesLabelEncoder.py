import pandas as pd
from sklearn.preprocessing import LabelEncoder

# Load the data from your sales CSV file
data = pd.read_csv("C:/Users/Henning/OneDrive/Personlige/WindowsPowerShell/Company_SalesData.csv")

# Apply label encoding to 'Product' and 'Region'
data['Product'] = LabelEncoder().fit_transform(data['Product'])
data['Region'] = LabelEncoder().fit_transform(data['Region'])

# Save the encoded data to a new file (optional, for reference)
data.to_csv("C:/Users/Henning/OneDrive/Personlige/WindowsPowerShell/Company_SalesDataEncoded.csv", index=False)

print("Data after encoding:")
print(data.head())


# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanySalesLabelEncoder.py