from flask import Flask, jsonify
import os
import wave
import threading
import pyaudio
import whisper
from pyannote.audio import Pipeline
from summary import summarize_text
from innocence import check_innocence
from ipc import predict_ipc_sections, generate_verdict

app = Flask(__name__)

# Set Hugging Face token for PyAnnote
os.environ["HF_TOKEN"] = "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"

# Load models
diarization_pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization", use_auth_token=os.environ["HF_TOKEN"])
whisper_model = whisper.load_model("medium")

# Audio recording settings
CHUNK = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
audio = pyaudio.PyAudio()
recording = False
frames = []
stream = None

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

@app.route("/stop_recording", methods=["GET"])
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
        transcript_text = " ".join([word["word"] for segment in transcription_result['segments'] for word in segment['words']])
        
        # Summarization
        summary = summarize_text(transcript_text)
        
        # Innocence Check
        innocence = check_innocence(summary)
        
        if innocence == 1:
            final_verdict_output = "The accused is found NOT GUILTY. No further processing needed."
        else:
            # IPC & Punishment Prediction
            matched_sections = predict_ipc_sections(summary)
            final_verdict_output = generate_verdict(summary, matched_sections)
        
        return jsonify({
            "status": "recording stopped",
            "final_verdict": final_verdict_output
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
