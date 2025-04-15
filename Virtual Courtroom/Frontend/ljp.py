import pandas as pd
from sklearn.model_selection import train_test_split
from transformers import AutoTokenizer, AutoModelForSequenceClassification, Trainer, TrainingArguments
from datasets import Dataset
import torch

# Load dataset
df = pd.read_csv("cases_cleaned.csv")
print(df.columns)

# Rename column and encode labels
df.rename(columns={"Judgement": "judgement"}, inplace=True)
df.columns = df.columns.str.strip().str.lower()  # Normalize column names
df["judgement"] = df["judgement"].map({"Guilty": 1, "Not Guilty": 0})  # Convert labels
df = df.dropna(subset=["judgement"])  # Remove rows with NaN values
df["judgement"] = df["judgement"].astype(int)  # Convert to integer

# Split dataset
train_texts, test_texts, train_labels, test_labels = train_test_split(
    df["case description"].tolist(),
    df["judgement"].tolist(),
    test_size=0.2,
    random_state=42
)

# Load tokenizer
tokenizer = AutoTokenizer.from_pretrained("distilbert-base-uncased")

# Tokenize texts
train_encodings = tokenizer(train_texts, truncation=True, padding=True, max_length=512)
test_encodings = tokenizer(test_texts, truncation=True, padding=True, max_length=512)

# Convert to Hugging Face dataset
train_dataset = Dataset.from_dict({
    "input_ids": train_encodings["input_ids"],
    "attention_mask": train_encodings["attention_mask"],
    "labels": train_labels  # Labels should be integers (0 or 1)
})

test_dataset = Dataset.from_dict({
    "input_ids": test_encodings["input_ids"],
    "attention_mask": test_encodings["attention_mask"],
    "labels": test_labels  # Labels should be integers (0 or 1)
})

# Load model with num_labels=2
model = AutoModelForSequenceClassification.from_pretrained("distilbert-base-uncased", num_labels=2)

# Define training arguments
training_args = TrainingArguments(
    output_dir="./results",
    eval_strategy="epoch",  # Fixed deprecated warning
    save_strategy="epoch",
    per_device_train_batch_size=4,
    per_device_eval_batch_size=4,
    num_train_epochs=5,
    logging_dir="./logs",
    logging_steps=10
)

# Define Trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_dataset,
    eval_dataset=test_dataset
)

# Start training
trainer.train()

model.save_pretrained("custom-legal-judgment-model")
tokenizer.save_pretrained("custom-legal-judgment-model")
from transformers import pipeline

# Load the trained model
classifier = pipeline("text-classification", model="custom-legal-judgment-model", tokenizer="custom-legal-judgment-model")

# Predict judgment for a new case
case_description = "The accused was caught attempting to bribe a government officer. Video evidence confirmed the offer."
prediction = classifier(case_description)

print(prediction)  # Example output: [{'label': 'LABEL_1', 'score': 0.97}] (LABEL_1 = Guilty, LABEL_0 = Not Guilty)
