import json
import os
import uuid
import logging
import boto3
from datetime import datetime

# ──── Set up logger ────────────────────────────────────────────────────────────
logger = logging.getLogger()
# 最細一階為 DEBUG，正式環境可調整為 INFO 以上
logger.setLevel(logging.DEBUG)

# ──── DynamoDB Client ─────────────────────────────────────────────────────────
dynamo = boto3.resource("dynamodb")
table = dynamo.Table(os.environ["EVENT_TABLE"])

def lambda_handler(event, context):
    logger.debug(f"[Entry] event: {json.dumps(event)}")

    # 驗證與解析
    try:
        body = json.loads(event.get("body", "{}"))
        logger.info(f"[Parse] body parsed successfully")
    except json.JSONDecodeError as e:
        logger.warning(f"[ParseError] 無法解析 JSON：{e}")
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid JSON payload"})
        }

    # 必填欄位驗證
    required = ["status", "schedule", "content", "person_in_charge"]
    for key in required:
        if key not in body:
            logger.warning(f"[Validate] Missing required field: {key}")
            return {
                "statusCode": 400,
                "body": json.dumps({"message": f"Missing field: {key}"})
            }
    logger.debug(f"[Validate] all required fields present")

    # 組裝 DynamoDB Item
    item = {
        "id": str(uuid.uuid4()),
        "status": body["status"],
        "schedule": body["schedule"],
        "content": body["content"],
        "person_in_charge": body["person_in_charge"],
        "create_time": body.get("create_time", datetime.utcnow().isoformat() + "Z"),
        "update_time": body.get("update_time", datetime.utcnow().isoformat() + "Z")
    }
    logger.debug(f"[Item] constructed item: {json.dumps(item)}")

    # 寫入 DynamoDB
    try:
        table.put_item(Item=item)
        logger.info(f"[DynamoDB] wrote item successfully, id={item['id']}")
    except Exception as e:
        # exc_info=True 會把 stack trace 一起輸出到 log
        logger.error("[DynamoDBError] failed to write item", exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Internal server error",
                "error": str(e)
            })
        }

    # 成功回應
    logger.info(f"[Response] returning 201 Created for id={item['id']}")
    return {
        "statusCode": 201,
        "body": json.dumps({
            "message": "Event created",
            "event_id": item["id"]
        })
    }
