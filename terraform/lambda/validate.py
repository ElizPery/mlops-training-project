def lambda_handler(event, context):
    print("Validating data...")
    source = event.get("source", "unknown")
    commit = event.get("commit", "unknown")
    print(f"Triggered from {source}, commit: {commit}")
    
    return {
        "statusCode": 200,
        "status": "VALIDATED",
        "source": source,
        "commit": commit
    }