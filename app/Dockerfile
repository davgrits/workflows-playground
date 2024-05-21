FROM python:3.8.13-alpine3.15

COPY requirements.txt .
RUN pip install -r requirements.txt

EXPOSE 5000

COPY main-new.py .

ENTRYPOINT FLASK_APP=main-new.py flask run --host=0.0.0.0
