#!/usr/bin/env python3

import json
import urllib.parse
import logging
import boto3
import io
from deps.PIL import Image

#############################
# Setup
#############################
logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
MAX_SIZE       = (500,500)
QUEUE_FOLDER   = 'queued'
NEW_FOLDER     = 'processed'
ARCHIVE_FOLDER = 'raw'

#############################
# Helpers
#############################
def get_bucket_name(event):
    return event['Records'][0]['s3']['bucket']['name']

def get_key(event):
    key = event['Records'][0]['s3']['object']['key']
    return urllib.parse.unquote_plus(key, encoding='utf-8')

def file_parts(f):
    return f.rsplit('.', 1)

def pillow_to_bytes(pillow_img):
    in_mem_file = io.BytesIO()
    pillow_img.save(in_mem_file, format=pillow_img.format)
    in_mem_file.seek(0)
    return in_mem_file

def thumbnail_name(key):
    fname, ext = file_parts(key)
    new_key    = fname + '-500.' + ext
    return new_key.replace(QUEUE_FOLDER, NEW_FOLDER)

def archive_name(key):
    fname, ext = file_parts(key)
    new_key    = fname + '-raw.' + ext
    return new_key.replace(QUEUE_FOLDER, ARCHIVE_FOLDER)

#############################
# Main
#############################
def main(event, context):
    bucket = get_bucket_name(event)
    key    = get_key(event)
    try:
        logger.info(f'Processing file created event: s3://{bucket}/{key}')
        response = s3.get_object(Bucket=bucket, Key=key)
        logger.info(f"Retrieved file from s3://{bucket}/{key}. CONTENT TYPE: " + response['ContentType'])

        # Resize image
        img = Image.open(response['Body'])
        img.thumbnail(MAX_SIZE)

        # Persist file to S3
        thumbnail_key = thumbnail_name(key)
        logger.info(f"Uploading to s3://{bucket}/{thumbnail_key}")
        s3.upload_fileobj(pillow_to_bytes(img), bucket, thumbnail_key)
        logger.info(f"Successful upload to s3://{bucket}/{thumbnail_key}")

        # Move file to "archive"
        src_file    = f'/{bucket}/{key}'
        archive_key = archive_name(key)
        logger.info(f"Archiving s3://{bucket}/{key} to s3://{bucket}/{archive_key}")
        s3.copy_object(Bucket=bucket, CopySource=src_file, Key=archive_key)
        logger.info(f"Successfully Created Archive File s3://{bucket}/{archive_key}")
        s3.delete_object(Bucket=bucket, Key=key)
        logger.info(f"Successfully Deleted Original s3://{bucket}/{key}")

        return response['ContentType']
    except Exception as e:
        logger.error(e)
        logger.error(f'Error getting object {bucket}/{key}. Does the file exist?')
        raise e


# test_img = s3.get_object(Bucket='andrewslai-wedding', Key='queued/clojure-logo.jpg')['Body']

# >>> test_img
# botocore.response.StreamingBody object at 0x7f4ca56112b0

# test_thumb = Image.open(test_img)
# test_thumb.thumbnail(MAX_SIZE)
# test_thumb.save('/home/andrew/dev/image-processor/clojure-logo.thumb.jpg')
