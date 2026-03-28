#WARNING - has to run from Python command line 
# Is only running >>> models/gpt2 <<<<<<<<<<<<<<<<<< Just an example
import requests

API_URL = "https://api-inference.huggingface.co/models/gpt2"
headers = {"Authorization": "Bearer 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"}

def query(payload):
    data = {"inputs": payload}
    response = requests.post(API_URL, headers=headers, json=data)
    return response.json()

output = query("Can you explain machine learning?")
print(output)

# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanyTrainSalesForecastModel.py


 