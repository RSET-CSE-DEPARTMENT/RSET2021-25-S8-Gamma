from transformers import T5Tokenizer, T5ForConditionalGeneration
# from transcript import *

tokenizer = T5Tokenizer.from_pretrained("./t5_legal_model_final",extra_ids=100)
model = T5ForConditionalGeneration.from_pretrained("./t5_legal_model_final")

def summarize_text(text):
    input_text = "summarize: " + text
    input_ids = tokenizer.encode(input_text, return_tensors="pt", max_length=512, truncation=True)
    summary_ids = model.generate(input_ids, max_length=150, min_length=80, num_beams=8, early_stopping=True,repetition_penalty=2.1)
    return tokenizer.decode(summary_ids[0], skip_special_tokens=True)

# summary = summarize_text(case3)
# print("\n")
# print(summary)
# print("\n")



# # summary.py
# from transformers import T5Tokenizer, T5ForConditionalGeneration

# tokenizer = T5Tokenizer.from_pretrained("./t5_legal_model_final")
# model = T5ForConditionalGeneration.from_pretrained("./t5_legal_model_final", trust_remote_code=True)

# with open("transcript.txt", "r", encoding="utf-8") as f:
#     input_text = f.read()

# input_ids = tokenizer.encode("summarize: " + input_text, return_tensors="pt", truncation=True, max_length=512)
# summary_ids = model.generate(input_ids, max_length=150, min_length=80)
# summary = tokenizer.decode(summary_ids[0], skip_special_tokens=True)

# print("\nSUMMARY:\n", summary)


"""

from transformers import T5Tokenizer, T5ForConditionalGeneration
from transcript import case3  # Assuming case3 is the transcript string

# STEP 1: Load tokenizer (with extra_ids=100) and save if not already saved
tokenizer = T5Tokenizer.from_pretrained("t5-base", extra_ids=100)
tokenizer.save_pretrained("./t5_legal_model_final")  # Only needed once

# STEP 2: Load the model from pretrained (use from_flax=True if only Flax weights are present)
try:
    model = T5ForConditionalGeneration.from_pretrained("./t5_legal_model_final")
except OSError:
    # If only Flax weights are available
    model = T5ForConditionalGeneration.from_pretrained("./t5_legal_model_final", from_flax=True)
    model.save_pretrained("./t5_legal_model_final")  # Convert to PyTorch format for future use

# STEP 3: Define the summarization function
def summarize_text(text):
    input_text = "summarize: " + text.strip()
    input_ids = tokenizer.encode(input_text, return_tensors="pt", max_length=512, truncation=True)
    summary_ids = model.generate(
        input_ids,
        max_length=150,
        min_length=80,
        num_beams=8,
        early_stopping=True,
        repetition_penalty=2.1
    )
    return tokenizer.decode(summary_ids[0], skip_special_tokens=True)

# STEP 4: Run the summary
summary = summarize_text(case3)

# Print the result
print("\nSummary:\n")
print(summary)
print("\n")
"""