FROM python:3.10
ENV PYTHONUNBUFFERED True
COPY requirements.txt ./
RUN pip install -r requirements.txt
RUN apt-get update && apt-get install -y default-jdk
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app