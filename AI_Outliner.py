import sys
import requests
import json
import os

# === CONFIG ===
TREE_FILE = "OutlinerTree.md"  # Path to your saved tree file

# === ARGUMENT HANDLING ===
if len(sys.argv) < 2:
    print("Usage: python AI_Outliner.py <command> [input_text] [model]")
    sys.exit(1)

command = sys.argv[1].upper()
input_text = sys.argv[2] if len(sys.argv) > 2 else ""

# model = sys.argv[3] if len(sys.argv) > 3 else "mistralai/mistral-7b-instruct:free"
# model = sys.argv[3] if len(sys.argv) > 3 else "anthropic/claude-3-haiku"
# model = sys.argv[3] if len(sys.argv) > 3 else "openai/gpt-3.5-turbo"
# model = sys.argv[3] if len(sys.argv) > 3 else "openai/gpt-4"
# model = sys.argv[3] if len(sys.argv) > 3 else "cohere/command-r-plus"
# model = sys.argv[3] if len(sys.argv) > 3 else "google/gemini-pro"
model = sys.argv[3] if len(sys.argv) > 3 else "mistralai/mixtral-8x7b-instruct"

# === API SETUP ===
API_URL = "https://openrouter.ai/api/v1/chat/completions"
headers = {
    "Authorization": "Bearer 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",
    "Content-Type": "application/json"
}

# === PROMPT BUILDING ===
def build_prompt(command, text):
    if command == "G":  # Generate tree
        return f"Analyze the following manuscript and create a structured outline or tree with navigable nodes:\n\n{text}"
    elif command == "D":  # Display tree
        if os.path.exists(TREE_FILE):
            with open(TREE_FILE, "r", encoding="utf-8") as f:
                tree_content = f.read()
            return f"Display the following outline/tree in a readable and compact format:\n\n{tree_content}"
        else:
            return "Tree file not found."
    elif command == "S":  # Save tree
        return f"{text}"
    # elif command == "B":  # Clarify branch (unused)
    #     return f"Clarify and expand on the following part of an outline/tree for better AI understanding:\n\n{text}"
    elif command == "C":  # Generate code
        return f"You are a senior software engineer. Based on the following system component description or specification, generate clean, commented, production-quality code in an appropriate language:\n\n{text}"
    else:
        return f"Unknown command: {command}"

# === REQUEST EXECUTION ===
def query(prompt, model):
    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}]
    }
    try:
        response = requests.post(API_URL, headers=headers, data=json.dumps(data), timeout=30)
        response.raise_for_status()
        result = response.json()
        return result['choices'][0]['message']['content']
    except requests.exceptions.Timeout:
        return "Request timed out after 30 seconds."
    except requests.exceptions.RequestException as e:
        return f"Request failed: {str(e)}"
    except Exception as e:
        return f"Unexpected error: {str(e)}"

# === MAIN EXECUTION ===
if __name__ == "__main__":
    prompt = build_prompt(command, input_text)
    output = query(prompt, model)
    print(output)



