import pandas as pd
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer
# from summary import summarize_text
# from innocence import check_innocence
#from transcript import *


def predict_ipc_section(case_summary):
    # Check innocence first
    # innocence = check_innocence(case_summary)
    # if innocence == 1:
    #     print("Victim found INNOCENT")
    #     return

    # Load dataset
    ipc_data = pd.read_csv("ipc_dataset_nlp.csv")
    ipc_data = ipc_data.astype(str)  # Ensure all text columns are strings

    # Load the best SBERT model
    model = SentenceTransformer("all-mpnet-base-v2")

    # Convert descriptions to embeddings
    ipc_data["embedding"] = ipc_data["Description"].apply(lambda x: model.encode(x))
    ipc_vectors = np.array(ipc_data["embedding"].tolist())

    print("Shape of IPC embeddings:", ipc_vectors.shape)  # Expected: (N, 768)

    # Define the embedding dimension
    dimension = ipc_vectors.shape[1]

    # Create and populate FAISS index
    index = faiss.IndexFlatL2(dimension)
    index.add(ipc_vectors)

    print("FAISS Index built with", index.ntotal, "entries")

    # Convert case summary into an embedding
    summary_vector = model.encode(case_summary).reshape(1, -1)

    # Normalize the embeddings
    faiss.normalize_L2(ipc_vectors)
    faiss.normalize_L2(summary_vector)

    # Search using Cosine Similarity
    D, I = index.search(summary_vector, k=3)

    # Get matched IPC section details
    matched_sections = ipc_data.iloc[I[0]]

    # Display results
    for idx, row in matched_sections.iterrows():
        print(f"\n🔹 **Predicted IPC Section:** {row['Section']}")
        print(f"🔹 **Description:** {row['Description']}")
        print(f"🔹 **Punishment:** {row['Punishment']}")
        print(f"🔹 **Bailable/Non-Bailable:** {row['Bailable/Non-Bailable']}")

    return matched_sections

    # Generate and print final verdict
    # final_verdict_output = generate_verdict(case_summary, matched_sections)
    # print("\n")
    # print(final_verdict_output)
    # print("\n")

def generate_verdict(case_summary, matched_sections):
    convicted_sections = matched_sections["Section"].tolist()
    punishments = matched_sections["Punishment"].tolist()
    bail_statuses = matched_sections["Bailable/Non-Bailable"].tolist()

    # Determine final verdict (Guilty if at least one non-bailable section exists)
    verdict = "Guilty" if "non-bailable" in [status.lower() for status in bail_statuses] else "Not Guilty"

    punishment = "; ".join(set(punishments))
    bail_status = ", ".join(set(bail_statuses)).capitalize()

    # Format final verdict
    final_verdict = f"""
=============================================
                **DRAFT VERDICT**
=============================================
**Case Summary:**
   {case_summary}

**Final Verdict:**
   - The accused is found **{verdict}** under IPC Section(s) **{', '.join(convicted_sections)}**.
   - **Punishment:** {punishment}
   - **Bail Status:** {bail_status}
=============================================
"""
    return final_verdict

# i = predict_ipc_section(case_sum)
# print(i)

# print(generate_verdict(case_sum,i))