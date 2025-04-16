from flask import Flask, request, jsonify
import psycopg2
from psycopg2 import sql
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime, time
from tensorflow.keras.models import load_model



import os
import wave
import threading
import pyaudio
import whisper
from pyannote.audio import Pipeline
from summary import summarize_text
from innocence import check_innocence
from ipc import generate_verdict, predict_ipc_section

# Set Hugging Face token for PyAnnote
os.environ["HF_TOKEN"] = "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"




# Audio recording settings
CHUNK = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
audio = pyaudio.PyAudio()
recording = False
frames = []
stream = None




import traceback
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from flask_mail import Mail, Message
import time as std_time


from paddleocr import PaddleOCR as pdl
from werkzeug.utils import secure_filename

from flask_cors import CORS
app = Flask(__name__)
CORS(app)


# Database connection configuration
def get_db_connection():
    """Establish and return a database connection."""
    conn = psycopg2.connect(
        database="legal",
        user="postgres",
        host='localhost',
        password="123456",
        port=5432
    )
    return conn

#SIGNUP
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')

    if not name or not email or not password:
        return jsonify({'error': 'Missing fields'}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO Users (name, email, password_hash)
                VALUES (%s, %s, %s) RETURNING user_id, is_judge;
                """,
                (name, email, password)  # Store the password as plain text (no hashing)
            )
            result = cur.fetchone()
            conn.commit()
            user_id, is_judge = result
            return jsonify({'user_id': user_id, 'is_judge': is_judge}), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({'error': 'User with this email already exists'}), 409

# LOGIN
"""
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Missing fields'}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT user_id, password_hash, is_judge FROM Users WHERE email = %s", (email,))
            user = cur.fetchone()

            if user is None:
                return jsonify({'error': 'User not found'}), 404

            user_id, stored_password, is_judge = user
            if stored_password == password:
                return jsonify({'user_id': user_id, 'is_judge': is_judge}), 200
            else:
                return jsonify({'error': 'Incorrect password'}), 401
    except Exception as e:
        return jsonify({'error': 'An error occurred'}), 500
"""
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Missing fields'}), 400

    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT user_id, password_hash, is_judge FROM Users WHERE email = %s", (email,))
            user = cur.fetchone()

            if user is None:
                return jsonify({'error': 'User not found'}), 404

            user_id, stored_password, is_judge = user
            if stored_password == password:
                return jsonify({'user_id': user_id, 'is_judge': is_judge}), 200
            else:
                return jsonify({'error': 'Incorrect password'}), 401
    except Exception as e:
        return jsonify({'error': 'An error occurred'}), 500

# REFERENCE ID PASS KEY CHECK
"""
@app.route('/api/validate_case', methods=['POST'])
def validate_case():
    data = request.get_json()
    reference_id = data.get('reference_id')
    pass_key = data.get('pass_key')

    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        SELECT * FROM cases WHERE reference_id = %s AND passkey = %s
    , (reference_id, pass_key))

    case = cursor.fetchone()
    cursor.close()

    if case:
        return jsonify({
            "status": "success",
            "case_id": case[0],
        }), 200
    else:
        return jsonify({"status": "error", "message": "Invalid reference ID or pass key"}), 401
"""
@app.route('/api/validate_case', methods=['POST'])
def validate_case():
    data = request.get_json()
    reference_id = data.get('reference_id')
    pass_key = data.get('pass_key')
    user_id = data.get('user_id')  # Get the user_id from the request

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            """
            SELECT case_id FROM cases
            WHERE reference_id = %s AND passkey = %s
            """, (reference_id, pass_key)
        )
        case = cur.fetchone()

        if case:
            case_id = case[0]
            cur.execute(
                """
                UPDATE cases
                SET defendant_id = %s
                WHERE case_id = %s
                """, (user_id, case_id)
            )
            conn.commit()
            cur.close()
            conn.close()
            return jsonify({'case_id': case_id}), 200
        else:
            cur.close()
            conn.close()
            return jsonify({'message': 'Invalid reference ID or pass key'}), 400

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# SAVE TEMP SLOTS (from prosecutor)
@app.route('/api/save_temp_slot', methods=['POST'])
def save_temp_slot():
    data = request.get_json()
    print("Received data:", data)  # Log the received data for debugging

    try:
        prosecutor_id = data['prosecutor_id']
        case_id = data['case_id']
        date = data['date']
        slots = data['slots']
    except KeyError as e:
        return jsonify({"error": f"Missing key: {str(e)}"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    for slot in slots:
        try:
            start_time = slot['start_time']
            end_time = slot['end_time']

            cursor.execute("""
                INSERT INTO temp_slots (case_id, prosecutor_id, date, start_time, end_time)
                VALUES (%s, %s, %s, %s, %s)
            """, (case_id, prosecutor_id, date, start_time, end_time))
        except KeyError as e:
            return jsonify({"error": f"Missing key in slot: {str(e)}"}), 400

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Slots saved successfully!"}), 201

# FETCH TEMP SLOTS
@app.route('/api/temp_slots', methods=['GET'])
def get_temp_slots():
    case_id = request.args.get('case_id')
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT * FROM temp_slots WHERE case_id = %s
    """, (case_id,))

    temp_slots = cursor.fetchall()
    cursor.close()
    conn.close()

    def format_time(value):
        if isinstance(value, datetime):
            return value.strftime("%H:%M:%S")
        elif isinstance(value, time):
            return value.strftime("%H:%M:%S")
        return str(value)

    temp_slots_list = [{
        'temp_slot_id': slot[0],
        'case_id': slot[1],
        'prosecutor_id': slot[2],
        'date': slot[3],
        'start_time': format_time(slot[4]),
        'end_time': format_time(slot[5]),
    } for slot in temp_slots]

    return jsonify(temp_slots_list), 200

# CONFIRM SLOT
@app.route('/api/confirm_slot', methods=['POST'])
def confirm_slot():
    data = request.get_json()
    case_id = data['case_id']
    date = data['date']
    start_time = data['start_time']
    end_time = data['end_time']

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Get defendant_id
        cursor.execute("""
            SELECT defendant_id FROM Cases WHERE case_id = %s
        """, (case_id,))
        result = cursor.fetchone()
        if result:
            defendant_id = result[0]
        else:
            cursor.close()
            conn.close()
            return jsonify({"message": "Case not found"}), 404

        # Get prosecutor_id
        cursor.execute("""
            SELECT prosecutor_id FROM Cases WHERE case_id = %s
        """, (case_id,))
        r = cursor.fetchone()
        if r:
            prosecutor_id = r[0]
        else:
            cursor.close()
            conn.close()
            return jsonify({"message": "Case not found"}), 404

        # Insert into Real_Slots
        cursor.execute("""
            INSERT INTO Real_Slots (case_id, date, start_time, end_time, booked_by_prosecutor_id, booked_by_defense_id)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (case_id, date, start_time, end_time, prosecutor_id, defendant_id))

        # Delete from Temp_Slots
        cursor.execute("""
            DELETE FROM Temp_Slots WHERE case_id = %s AND date = %s AND start_time = %s
        """, (case_id, date, start_time))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"message": "Slot confirmed successfully!"}), 200

    except Exception as e:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
        return jsonify({"error": str(e)}), 500






app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'legalcourtroom@gmail.com'
app.config['MAIL_PASSWORD'] = 'lftv efdz akbt rdtq'
app.config['MAIL_DEFAULT_SENDER'] = 'njinesh239@gmail.com'

mail = Mail(app)








@app.route('/send-email', methods=['POST'])
def send_email():
    """Send an email to the defendant with case details."""
    try:
        data = request.json
        recipient = data.get('defendant_email')
        ref_id = data.get('reference_id')
        passkey = data.get('passkey')

        if not recipient:
            return jsonify({"error": "Recipient email is required"}), 400

        msg = Message(
            subject="Case Booking Confirmation",
            recipients=[recipient],
            body=f"We are writing to inform you that a case has been registered in your name. Below are the details of the case and the necessary credentials for you to access it.\n\nReference ID: {ref_id}\nPasskey: {passkey}.\nPlease keep these details safe and use the passkey to log in and access the petition and related documents.\n\nBest regards,\nVirtual Courtroom"
        )

        mail.send(msg)
        return jsonify({"message": "Email sent successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/store-case', methods=['POST'])
def store_case():
    """Store case details in the PostgreSQL database."""
    data = request.get_json()
    case_name = data.get('case_name')
    reference_id = data.get('reference_id')
    passkey = data.get('passkey')
    prosecutor_id = data.get('user_id')
    
    print(data)
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO cases (case_name, reference_id, passkey, prosecutor_id)
            VALUES (%s, %s, %s, %s)
            RETURNING case_id
            """, (case_name, reference_id, passkey, prosecutor_id)
        )
        case_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'Case details stored successfully', 'case_id': case_id}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500











@app.route('/savefileid', methods=['POST'])
def save_file_id():
    """Save the file ID associated with a case."""
    data = request.get_json()
    file_id = data.get('file_id')
    case_id = data.get('case_id')  # Use case_id instead of reference_id

    if not file_id or not case_id:
        return jsonify({'error': 'File ID and Case ID are required'}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute("""
            UPDATE cases
            SET file_id = %s
            WHERE case_id = %s
        """, (file_id, case_id))

        conn.commit()

        if cur.rowcount == 0:
            return jsonify({'error': 'Case not found for the given case ID'}), 404

        return jsonify({'message': 'File ID saved successfully'}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cur.close()
        conn.close()



@app.route('/get_file_id', methods=['POST'])
def get_file_id():
    """Retrieve the file ID corresponding to a case ID."""
    data = request.json
    case_id = data.get('case_id')

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT file_id FROM cases WHERE case_id = %s', (case_id,))
    file_id = cur.fetchone()
    conn.close()

    if file_id:
        return jsonify({'file_id': file_id[0]}), 200
    else:
        return jsonify({'error': 'File ID not found for the given case ID'}), 404









# Configurations
UPLOAD_FOLDER = 'uploads/'
ALLOWED_EXTENSIONS = {'pdf'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
ocr = pdl(use_angle_cls=True, lang='en')

# Ensure the upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# def upload_to_google_drive(file_path, filename):
#     media = MediaFileUpload(file_path, mimetype='application/pdf')
#     file_metadata = {'name': filename, 'parents': ['1bh35rYdDPH_0WZBhj_SCioRyXe9tojTw']}

#     uploaded_file = drive_service.files().create(
#         body=file_metadata,
#         media_body=media,
#         fields='id'
#     ).execute()

#     drive_service.permissions().create(
#         fileId=uploaded_file['id'],
#         body={'role': 'reader', 'type': 'anyone'}
#     ).execute()

#     return uploaded_file.get('id')

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/upload-and-process-ocr', methods=['POST'])
def upload_and_process_ocr():
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)

        # Perform OCR on the uploaded file
        result = ocr.ocr(file_path, cls=True)
        texts = [line[-1][0] for line in result[0]]

        # Save the OCR-ed text to a file
        text_file_path = file_path.replace('.pdf', '.txt')
        with open(text_file_path, 'w', encoding='utf-8') as text_file:
            for text in texts:
                text_file.write(text + '\n')

        # Extract case_id from the request (assumed to be passed as part of the request)
        case_id = request.form.get('case_id')
        if case_id:
            try:
                # Insert the OCR-ed text into the 'case_petition' column in the 'cases' table
                conn = get_db_connection()
                cur = conn.cursor()
                
                # Insert or Update the case petition text
                query = sql.SQL("""
                    UPDATE cases 
                    SET case_petition = %s 
                    WHERE case_id = %s
                """)
                cur.execute(query, (open(text_file_path, 'r').read(), case_id))
                conn.commit()

                cur.close()
                conn.close()

                return jsonify({
                    'message': 'OCR processed and text saved to database',
                    'text_file_path': text_file_path
                }), 200
            except Exception as e:
                print(f"Error inserting OCR text into database: {e}")
                return jsonify({'error': 'Failed to insert OCR text into database'}), 500
        else:
            return jsonify({'error': 'Case ID not provided'}), 400
    else:
        return jsonify({'error': 'Invalid file format'}), 400

@app.route('/get_case_text', methods=['POST'])
def get_case_text():
    try:
        data = request.get_json()
        case_id = data.get("case_id")

        if not case_id:
            return jsonify({"error": "Case ID is required"}), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT case_petition FROM cases WHERE case_id = %s", (case_id,))
        row = cursor.fetchone()
        conn.close()

        if row:
            return jsonify({"case_text": row[0]})
        else:
            return jsonify({"error": "Case not found"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500    


@app.route('/sendemail1', methods=['POST'])
def send_email1():
    """Send an email when the slot is confirmed."""
    try:
        data = request.json
        receiver_email = data.get('email')  # Email passed from frontend
        case_id = data.get('case_id')  # Case ID
        date = data.get('date')  # Selected date
        start_time = data.get('start_time')  # Start time of the slot
        end_time = data.get('end_time')  # End time of the slot

        # Validate if the required data exists
        if not receiver_email or not case_id or not date or not start_time or not end_time:
            return jsonify({"error": "Missing required fields"}), 400

        # Construct email body with the selected slot details
        email_body = f"""
        Dear Prosecutor,

        We are writing to inform you that your time slot for the case with Case ID: {case_id} has been confirmed. Below are the details of the scheduled slot:

        Date: {date}
        Time: {start_time} to {end_time}

        Please make a note of this information, and ensure to be available for the scheduled slot.

        Best regards,
        Virtual Courtroom
        """

        # Send email
        msg = Message(
            subject="Slot Confirmation for Your Case",
            recipients=[receiver_email],  # Receiver email passed from frontend
            body=email_body,
            sender='legalcourtroom@gmail.com'
        )

        mail.send(msg)
        return jsonify({"message": "Email sent successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500



###########################################################################################
####                                    JUDGE                                         #####
###########################################################################################


@app.route('/get_booked_cases', methods=['GET'])
def get_booked_cases():
    today_date = datetime.today().strftime('%Y-%m-%d')
    try:
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("""
                SELECT case_id, date, start_time, end_time
                FROM real_slots
                WHERE date = %s;
            """, (today_date,))
            booked_cases = cur.fetchall()

            # Convert time fields to string format
            for case in booked_cases:
                case["start_time"] = case["start_time"].strftime("%H:%M:%S")
                case["end_time"] = case["end_time"].strftime("%H:%M:%S")
        
        conn.close()
        return jsonify(booked_cases), 200
    except Exception as e:
        print("Error fetching booked cases:", str(e))  # Debugging line
        return jsonify({'error': str(e)}), 500


MODEL_PATH = "F:\\projectgithub\\vcodey\\lib\\weapon_detection_model.h5"
model = load_model(MODEL_PATH)

# Define class labels

# Define class labels
CLASS_LABELS = ["Gun", "Knife", "No Weapon"]
@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Logging to track file upload
        print("Request received for /predict endpoint.")

        # Check if file is present in the request
        if 'file' not in request.files:
            print("Error: No file uploaded.")
            return jsonify({'error': 'No file uploaded'}), 400

        file = request.files['file']
        print(f"Uploaded file: {file.filename}")

        if file.filename == '':
            print("Error: Empty filename.")
            return jsonify({'error': 'Empty filename'}), 400

        # Read image from uploaded file
        print("Reading image...")
        img_array = np.frombuffer(file.read(), np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        if img is None:
            print("Error: Invalid image format.")
            return jsonify({'error': 'Invalid image format'}), 400

        # Preprocess image
        print("Preprocessing image...")
        img = cv2.resize(img, (224, 224))  # Resize to match model input size
        img = np.expand_dims(img, axis=0) / 255.0  # Normalize pixel values

        # Make prediction
        print("Making prediction...")
        predictions = model.predict(img)
        print(f"Raw predictions: {predictions}")

        predicted_class = CLASS_LABELS[np.argmax(predictions)]
        confidence = float(np.max(predictions))  # Get confidence score
        print(f"Predicted class: {predicted_class}, Confidence: {confidence}")

        # Return prediction result
        return jsonify({
            'prediction': predicted_class,
            'confidence': confidence
        })

    except Exception as e:
        # Log the error with detailed information
        print(f"Server Error: {str(e)}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500








# Load models
diarization_pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization", use_auth_token=os.environ["HF_TOKEN"])
whisper_model = whisper.load_model("medium")

def record_audio():
    global recording, frames, stream
    frames = []
    stream = audio.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)
    
    while recording:
        data = stream.read(CHUNK)
        frames.append(data)

@app.route("/start_recording", methods=["GET"])
def start_recording():
    global recording
    if not recording:
        recording = True
        threading.Thread(target=record_audio).start()
        return jsonify({"status": "recording started"})
    return jsonify({"status": "already recording"})

"""@app.route("/stop_recording", methods=["GET"])
def stop_recording():
    global recording, stream
    if not recording:
        return jsonify({"status": "not recording"})

    try:
        recording = False
        stream.stop_stream()
        stream.close()

        # Save to file
        wav_file = "recorded_audio.wav"
        with wave.open(wav_file, "wb") as wf:
            wf.setnchannels(CHANNELS)
            wf.setsampwidth(audio.get_sample_size(FORMAT))
            wf.setframerate(RATE)
            wf.writeframes(b''.join(frames))

        # Speaker Diarization
        diarization = diarization_pipeline(wav_file, min_speakers=3, max_speakers=5)

        # Speech-to-text transcription
        transcription_result = whisper_model.transcribe(wav_file, word_timestamps=True)
        print("Transcription Result:", transcription_result)  # Debugging line

        # Match words to speakers
        speaker_segments = {}
        for turn, _, speaker in diarization.itertracks(yield_label=True):
            if speaker not in speaker_segments:
                speaker_segments[speaker] = []
            speaker_segments[speaker].append((turn.start, turn.end))

        speaker_transcriptions = {speaker: [] for speaker in speaker_segments.keys()}
        for segment in transcription_result['segments']:
            for word in segment['words']:
                word_start = word["start"]
                word_text = word["word"]

                for speaker, time_ranges in speaker_segments.items():
                    for start, end in time_ranges:
                        if start <= word_start <= end:
                            speaker_transcriptions[speaker].append(word_text)
                            break  

        # Assign speaker roles
        role_mapping = {}
        role_keywords = {
            "Prosecutor": ["prosecutor", "prosecution"],
            "Defense": ["defense"],
            "Judge": ["judge"],
            "Witness": ["witness1","witness2","witness3","witness4"]
        }

        def clean_text(text):
            return "".join(e for e in text if e.isalnum() or e.isspace()).lower().strip()

        speaker_count = 1
        for speaker, words in speaker_transcriptions.items():
            full_text = " ".join(words).strip()
            cleaned_text = clean_text(full_text)
            detected_role = None

            for role, keywords in role_keywords.items():
                if any(keyword in cleaned_text for keyword in keywords):
                    detected_role = role
                    break  

            role_mapping[speaker] = detected_role if detected_role else f"Speaker {speaker_count}"
            speaker_count += 1

        # Prepare JSON response
        final_transcription = {role_mapping[speaker]: " ".join(words) for speaker, words in speaker_transcriptions.items()}
        # with open("transcript.txt", "w", encoding="utf-8") as f:
        #     f.write(final_transcription)
            
        # case_sum = summarize_text(final_transcription)
        # print(case_sum)
        # innocence = check_innocence(case_sum)
        # print(innocence)
        # ipc = predict_ipc_section(case_sum)
        # print(ipc)
        # print(generate_verdict(case_sum,ipc))
    
        return jsonify({
    "status": "recording stopped",
    "transcription": final_transcription
})


    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})"""



def record_audio():
    global frames, stream
    stream = audio.open(format=FORMAT, channels=CHANNELS,
                        rate=RATE, input=True,
                        frames_per_buffer=CHUNK)
    while recording:
        data = stream.read(CHUNK)
        frames.append(data)


@app.route("/stop_recording", methods=["GET"])
def stop_recording():
    global recording, stream, frames
    if not recording:
        return jsonify({"status": "not recording"})

    try:
        recording = False
        stream.stop_stream()
        stream.close()

        # Define absolute file path
        wav_file = "F:/projectgithub/vcodey/lib/recorded_audio.wav"

        # Save recorded audio to .wav file
        with wave.open(wav_file, "wb") as wf:
            wf.setnchannels(CHANNELS)
            wf.setsampwidth(audio.get_sample_size(FORMAT))
            wf.setframerate(RATE)
            wf.writeframes(b''.join(frames))

        # Make sure file is actually saved
        if not os.path.exists(wav_file):
            raise FileNotFoundError(f"WAV file not found at {wav_file}")

        print("✅ WAV file saved:", wav_file, "| Size:", os.path.getsize(wav_file), "bytes")

        # --- Speaker Diarization ---
        diarization = diarization_pipeline(wav_file, min_speakers=3, max_speakers=5)

        # --- Transcription ---
        try:
            print("🎤 Starting transcription using Whisper...")
            transcription_result = whisper_model.transcribe(wav_file, word_timestamps=True)
            print("✅ Transcription Result:", transcription_result)
        except Exception as whisper_error:
            print("❌ Whisper error:", str(whisper_error))
            return jsonify({"status": "error", "message": f"Whisper failed: {str(whisper_error)}"})

        # --- Match Words to Speakers ---
        speaker_segments = {}
        for turn, _, speaker in diarization.itertracks(yield_label=True):
            speaker_segments.setdefault(speaker, []).append((turn.start, turn.end))

        speaker_transcriptions = {speaker: [] for speaker in speaker_segments}
        for segment in transcription_result['segments']:
            for word in segment['words']:
                word_start = word["start"]
                word_text = word["word"]

                for speaker, time_ranges in speaker_segments.items():
                    if any(start <= word_start <= end for start, end in time_ranges):
                        speaker_transcriptions[speaker].append(word_text)
                        break

        # --- Assign Speaker Roles ---
        role_mapping = {}
        role_keywords = {
            "Prosecutor": ["prosecutor", "prosecution"],
            "Defense": ["defense"],
            "Judge": ["judge"],
            "Witness": ["witness1", "witness2", "witness3", "witness4"]
        }

        def clean_text(text):
            return "".join(e for e in text if e.isalnum() or e.isspace()).lower().strip()

        speaker_count = 1
        for speaker, words in speaker_transcriptions.items():
            full_text = " ".join(words)
            cleaned = clean_text(full_text)
            role = next((r for r, kw in role_keywords.items() if any(k in cleaned for k in kw)), None)
            role_mapping[speaker] = role if role else f"Speaker {speaker_count}"
            speaker_count += 1

        final_transcription = {role_mapping[s]: " ".join(w) for s, w in speaker_transcriptions.items()}
        final_transcription = "\n".join([f"{speaker}: {text}" for speaker, text in final_transcription.items()])
        print("FINAL TRANSCRIPT: \n",final_transcription)

        case_sum = summarize_text(final_transcription)
        print("Start HERE: \n",case_sum)
        inn = check_innocence(case_sum)
        print("innocence : ",inn)
        ipc = predict_ipc_section(case_sum)
        print("IPC here: \n",ipc)
        verdict = generate_verdict(case_sum,ipc)
        print("Draft Verdict : \n",verdict)

        return jsonify({
            "status": "recording stopped",
            "transcription": verdict
        })

    except Exception as e:
        print("❌ General error:", str(e))
        return jsonify({"status": "error", "message": str(e)})
    
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

