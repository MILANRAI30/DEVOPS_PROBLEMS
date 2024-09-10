#Write a Python script that reads the patients.csv file, checks the last check-up date for each patient, and sends an email reminder to those patients who are due for their check-up. 

import pandas as pd
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from datetime import datetime, timedelta

# Configuration
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
USERNAME = 'medcare.reminders@gmail.com'
PASSWORD = 'reminders123'
FROM_EMAIL = USERNAME
SUBJECT = 'Reminder: Your Health Check-up is Due'

# Load patient data
df = pd.read_csv('patients.csv')

# Convert 'Last Check-up Date' to datetime
df['Last Check-up Date'] = pd.to_datetime(df['Last Check-up Date'])

# Define the check-up interval (e.g., 1 year)
CHECK_UP_INTERVAL = timedelta(days=365)

# Get today's date
today = datetime.now()

# Define a function to send email
def send_email(to_email, patient_name):
    msg = MIMEMultipart()
    msg['From'] = FROM_EMAIL
    msg['To'] = to_email
    msg['Subject'] = SUBJECT

    body = f"Dear {patient_name},\n\nThis is a reminder that your regular health check-up is due. Please schedule your appointment at the earliest convenience.\n\nBest regards,\nMedCare"
    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(USERNAME, PASSWORD)
        text = msg.as_string()
        server.sendmail(FROM_EMAIL, to_email, text)
        print(f'Email sent to {to_email}')
    except Exception as e:
        print(f'Failed to send email to {to_email}. Error: {e}')
    finally:
        server.quit()

# Check for patients due for check-up and send reminders
for index, row in df.iterrows():
    last_checkup_date = row['Last Check-up Date']
    patient_name = row['Name']
    patient_email = f"{row['Patient ID']}@example.com"  # Replace with actual email address if available

    if today - last_checkup_date > CHECK_UP_INTERVAL:
        send_email(patient_email, patient_name)
