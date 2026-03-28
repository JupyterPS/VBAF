# ALTERNATIVE: Run CompanyModel.py directly from "PYTHON" command line:
# python C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell\CompanyModel.py "Can you explain machine learning?"

# $wpPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell"
# cd $wpPath
# python CompanyTrainSalesForecastModel.py

# THIS IS LIKE RUNNING FROM COMPANYAI.PS1 
# $pythonExePath = "C:\Users\Henning\AppData\Local\Programs\Python\Python313\python.exe"
# $pythonScriptPath = "C:\Users\Henning\OneDrive\Personlige\WindowsPowerShell\AI_CompanyChat.py"
# $result = & $pythonExePath $pythonScriptPath "Can you explain machine learning?"
# Write-Output "Result: $result"

# WARNING >>>>>>>>>>>>>>>> Beneath has to be called from CompanyChatAI.ps1 - Herunder skiftes MODEL NAME   <<<<<<<<<<<<<<<<<<<<
#import sys
#import requests
#API_URL = "https://api-inference.huggingface.co/models/mistralai/Mistral-Nemo-Instruct-2407"              # Works
#API_URL = "https://api-inference.huggingface.co/models/meta-llama/Meta-Llama-3.1-70B-Instruct" 
#API_URL = "https://api-inference.huggingface.co/models/meta-llama/Llama-3.2-11B-Vision-Instruct"          # works
#API_URL = "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct"
#headers = {"Authorization": "Bearer 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"}


import sys
import requests

# Grab the question and optionally the model name from command line
question = sys.argv[1]
try:
    model_name = sys.argv[2]
except IndexError:
    model_name = "meta-llama/Meta-Llama-3.1-70B-Instruct"  # Default model

# Construct the API URL dynamically
API_URL = f"https://api-inference.huggingface.co/models/{model_name}"

# Replace this token with your Hugging Face access token                                                # Hugging Face
headers = {
    "Authorization": "Bearer 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"
}

def query(payload, max_length=600, num_return_sequences=1):
    data = {
        "inputs": payload,
        "parameters": {
            "max_length": max_length,
            "num_return_sequences": num_return_sequences,
        },
    }

    try:
        response = requests.post(API_URL, headers=headers, json=data, timeout=15)
        response.raise_for_status()  # Raise error for 4xx/5xx responses
        result = response.json()

        if isinstance(result, list) and "generated_text" in result[0]:
            return result[0]["generated_text"]
        elif isinstance(result, dict) and "error" in result:
            return f"API Error: {result['error']}"
        else:
            return "Unexpected response format from the model."

    except requests.exceptions.Timeout:
        return "Request timed out after 15 seconds."
    except requests.exceptions.RequestException as e:
        return f"Request failed: {str(e)}"

if __name__ == "__main__":
    output = query(question)
    print(output)