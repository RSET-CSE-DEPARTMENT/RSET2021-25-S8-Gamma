from transformers import pipeline
#from summary import *

# Load the trained model
classifier = pipeline("text-classification", model="custom-legal-judgment-model", tokenizer="custom-legal-judgment-model")

# # Sample case description for testing
# case_description = summary
# # Predict judgment
# prediction = classifier(case_description)

# print(prediction)
# label_map = {"LABEL_1": "Guilty", "LABEL_0": "Not Guilty"}
# prediction_label = label_map[prediction[0]['label']]

# print("\n")
# print(f"Prediction: {prediction_label} (Confidence: {prediction[0]['score']:.2f})")
# print("\n")

# if prediction_label == "Not Guilty":
#     innocence = 1
# else:
#     innocence = 0


def check_innocence(case_summary):
    prediction = classifier(case_summary)
    label_map = {"LABEL_1": "Guilty", "LABEL_0": "Not Guilty"}
    prediction_label = label_map[prediction[0]['label']]
    confidence = prediction[0]['score']
    
    print(f"Prediction: {prediction_label} (Confidence: {confidence:.2f})\n")
    if prediction_label == "Not Guilty":
        innocence = 1
    else:
        innocence = 0
    return 0

# innocence=check_innocence(summary)
# print(innocence)