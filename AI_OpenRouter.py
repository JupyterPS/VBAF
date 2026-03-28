import sys
import requests
import json

# Read input question and model from command line
question = sys.argv[1]
try:
    model = sys.argv[2]
except IndexError:
    model = "openrouter/mistral-7b-instruct"

# OpenRouter endpoint
API_URL = "https://openrouter.ai/api/v1/chat/completions"                                                  # OpenRouter

# Insert your actual OpenRouter API key here
headers = {
    "Authorization": "Bearer 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",   # OpenRouter
    "Content-Type": "application/json"
}

def query(question, model):
    data = {
        "model": model,
        "messages": [
            {"role": "user", "content": question}
        ]
    }

    try:
        response = requests.post(API_URL, headers=headers, data=json.dumps(data), timeout=15)
        response.raise_for_status()
        result = response.json()

        return result['choices'][0]['message']['content']

    except requests.exceptions.Timeout:
        return "Request timed out after 15 seconds."
    except requests.exceptions.RequestException as e:
        return f"Request failed: {str(e)}"
    except Exception as e:
        return f"Unexpected error: {str(e)}"

if __name__ == "__main__":
    output = query(question, model)
    print(output)