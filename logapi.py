from datetime import datetime
from flask import Flask, request, jsonify #pip install flask
#from google.cloud import storage #pip install google-cloud-storage


BUCKET_NAME = "logs"


app = Flask(__name__)


def upload_to_bucket(data, bucket_name, blob_name):
    print(data, bucket_name, blob_name)
    #storage_client = storage.Client()
    #bucket = storage_client.bucket(bucket_name)
    #blob = bucket.blob(blob_name)
    #blob.upload_from_string(data)


@app.route('/log', methods=['POST'])
def receive_json():
    data = request.json
    client_ip = request.remote_addr.replace('.', '_')
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    file_name = f"log_{client_ip}_{timestamp}.txt"
    upload_to_bucket(data['data'], BUCKET_NAME, file_name)
    return jsonify({})


if __name__ == '__main__':
    app.run(debug=True, port=5000)

