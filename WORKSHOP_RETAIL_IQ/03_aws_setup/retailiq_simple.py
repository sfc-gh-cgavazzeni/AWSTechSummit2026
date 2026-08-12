#!/usr/bin/env python3
"""
RetailIQ Simple Agent — Workshop Demo
Calls Snowflake MCP Server directly via HTTP, then Bedrock for synthesis.
No Strands framework dependency — just httpx + boto3.
"""
import boto3, json, httpx, sys, os

# Load credentials from Secrets Manager
sm = boto3.client("secretsmanager", region_name="eu-central-1")
creds = json.loads(sm.get_secret_value(SecretId="retailiq-workshop-credentials")["SecretString"])
MCP_URL = creds["snowflake_mcp_endpoint"]
PAT = creds["snowflake_pat_token"]

BEDROCK_MODEL = "eu.anthropic.claude-3-7-sonnet-20250219-v1:0"


def call_mcp_tool(question):
    """Call the Snowflake MCP server tool directly via HTTP."""
    headers = {"Authorization": f"Bearer {PAT}", "Content-Type": "application/json"}

    init_payload = {
        "jsonrpc": "2.0", "method": "initialize", "id": 0,
        "params": {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {"name": "retailiq-workshop", "version": "1.0"}
        }
    }

    tool_payload = {
        "jsonrpc": "2.0", "method": "tools/call", "id": 1,
        "params": {"name": "retailiq_agent", "arguments": {"text": question}}
    }

    with httpx.Client(timeout=120) as client:
        # Initialize session
        r = client.post(MCP_URL, json=init_payload, headers=headers)
        session_id = r.headers.get("mcp-session-id", "")
        if session_id:
            headers["mcp-session-id"] = session_id

        # Send initialized notification
        client.post(MCP_URL, json={
            "jsonrpc": "2.0", "method": "notifications/initialized"
        }, headers=headers)

        # Call the tool
        r2 = client.post(MCP_URL, json=tool_payload, headers=headers)
        result = r2.json()

        if "result" in result:
            content = result["result"].get("content", [])
            texts = [c.get("text", "") for c in content if c.get("type") == "text"]
            return " ".join(texts)
        elif "error" in result:
            return f"MCP Error: {result['error'].get('message', str(result['error']))}"
        return str(result)


def call_bedrock(question, context):
    """Send question + MCP context to Bedrock for final synthesis."""
    bedrock = boto3.client("bedrock-runtime", region_name="eu-central-1")
    prompt = (
        f"You are RetailIQ Assistant. Based on this data from our retail analytics system:\n\n"
        f"{context}\n\n"
        f"User question: {question}\n\n"
        f"Provide a clear, well-formatted answer. Use EUR for currency. Be concise."
    )
    resp = bedrock.converse(
        modelId=BEDROCK_MODEL,
        messages=[{"role": "user", "content": [{"text": prompt}]}],
        inferenceConfig={"maxTokens": 2000}
    )
    return resp["output"]["message"]["content"][0]["text"]


BANNER = """
╔══════════════════════════════════════════════════════════════╗
║        RetailIQ AI Assistant — Workshop Demo                 ║
║   Snowflake MCP Server + AWS Bedrock (direct mode)          ║
╚══════════════════════════════════════════════════════════════╝

Ask me anything about RetailIQ sales, customers, and feedback.
Type 'quit' to exit.
"""

if __name__ == "__main__":
    print(BANNER)
    while True:
        try:
            q = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break
        if not q or q.lower() in ("quit", "exit", "q"):
            print("Goodbye!")
            break

        print("  [1/2] Calling Snowflake MCP Server...")
        mcp_result = call_mcp_tool(q)

        if mcp_result and not mcp_result.startswith("MCP Error"):
            print("  [2/2] Calling Bedrock for synthesis...")
            answer = call_bedrock(q, mcp_result)
            print(f"\nRetailIQ: {answer}\n")
        else:
            print(f"\n  {mcp_result}\n")
