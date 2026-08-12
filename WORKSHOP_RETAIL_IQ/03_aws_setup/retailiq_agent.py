#!/usr/bin/env python3
"""
RetailIQ Bedrock AgentCore Workshop Agent
=========================================
This agent combines Snowflake Cortex Analyst (structured analytics) and
Cortex Search (customer reviews & support tickets) via the Snowflake Managed
MCP Server, orchestrated by AWS Bedrock through the Strands framework.

Prerequisites:
  pip install strands-agents strands-agents-tools boto3

Usage:
  python retailiq_agent.py
"""

import json
import logging
import os
import sys
import urllib.request
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from strands import Agent
from strands_tools.mcp_client import MCPClient, _create_transport_callable

# ──────────────────────────────────────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.WARNING,          # set to DEBUG to trace MCP calls
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[
        logging.StreamHandler(sys.stderr),
        logging.FileHandler(os.path.join(os.path.dirname(__file__), "logs", "agent.log"),
                            mode="a", encoding="utf-8"),
    ],
)
logger = logging.getLogger("retailiq")

# ──────────────────────────────────────────────────────────────────────────────
# Configuration
# ============================================================
# TODO: Fill in your workshop credentials
# ============================================================
# Option A — paste values directly here (fine for a workshop, never do this in prod)
# Option B — leave the defaults and let load_credentials_from_secrets_manager()
#             pick them up automatically when running on the workshop EC2 instance.
# ──────────────────────────────────────────────────────────────────────────────

SNOWFLAKE_MCP_ENDPOINT: str = (
    "https://YOUR_ACCOUNT_URL.snowflakecomputing.com/api/v2/databases/RETAILIQ_DB/schemas/ANALYTICS/mcp-servers/RETAILIQ_MCP_SERVER_AGENT"
    # Replace YOUR_ACCOUNT_URL with your account hostname (underscores → dashes)
)

SNOWFLAKE_PAT_TOKEN: str = (
    "YOUR_PAT_TOKEN_HERE"
    # TODO: Replace with your PAT from: ALTER USER <you> ADD PROGRAMMATIC ACCESS TOKEN RetailIQ_Token;
)

BEDROCK_MODEL_ID: str = (
    "eu.anthropic.claude-sonnet-4-20250514-v1:0"
    # Claude Sonnet 4 via Bedrock cross-region inference profile (EU).
    # Other options:
    #   "eu.anthropic.claude-3-5-sonnet-20241022-v2:0"  (Claude 3.5 Sonnet v2)
    #   "eu.anthropic.claude-3-7-sonnet-20250219-v1:0"  (Claude 3.7 Sonnet)
)

AWS_REGION: str = (
    os.environ.get("AWS_DEFAULT_REGION", "eu-central-1")
    # Uses the instance's region (set by CloudFormation) or defaults to Frankfurt
)

SECRETS_MANAGER_SECRET_NAME: str = "retailiq-workshop-credentials"


# ──────────────────────────────────────────────────────────────────────────────
# Credentials loader — Secrets Manager (used when running on EC2)
# ──────────────────────────────────────────────────────────────────────────────

def _is_running_on_ec2() -> bool:
    """Return True if we can reach the EC2 Instance Metadata Service (IMDSv2)."""
    try:
        # IMDSv2: first obtain a token
        req = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "10"},
            method="PUT",
        )
        with urllib.request.urlopen(req, timeout=1) as resp:
            return resp.status == 200
    except Exception:
        return False


def load_credentials_from_secrets_manager(secret_name: str = SECRETS_MANAGER_SECRET_NAME) -> dict:
    """
    Retrieve Snowflake credentials from AWS Secrets Manager.

    Returns a dict with keys:
      - snowflake_mcp_endpoint
      - snowflake_pat_token
      - snowflake_account

    Raises RuntimeError if the secret cannot be fetched.
    """
    client = boto3.client("secretsmanager", region_name=AWS_REGION)
    try:
        response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response["SecretString"])
        logger.info("Credentials loaded from Secrets Manager: %s", secret_name)
        return secret
    except client.exceptions.ResourceNotFoundException:
        raise RuntimeError(
            f"Secret '{secret_name}' not found in Secrets Manager (region: {AWS_REGION}). "
            "Check that the CloudFormation stack deployed successfully and that "
            "the EC2 instance role has secretsmanager:GetSecretValue permission."
        )
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"AWS error loading credentials: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Secret value is not valid JSON: {exc}") from exc


def resolve_credentials() -> tuple[str, str]:
    """
    Determine MCP endpoint and PAT token, preferring Secrets Manager when on EC2
    and falling back to the module-level constants above.

    Returns: (mcp_endpoint, pat_token)
    """
    global SNOWFLAKE_MCP_ENDPOINT, SNOWFLAKE_PAT_TOKEN  # noqa: PLW0603

    if _is_running_on_ec2():
        logger.info("EC2 metadata service detected — loading credentials from Secrets Manager")
        try:
            creds = load_credentials_from_secrets_manager()
            return creds["snowflake_mcp_endpoint"], creds["snowflake_pat_token"]
        except RuntimeError as exc:
            logger.warning("Secrets Manager lookup failed (%s); falling back to hardcoded values", exc)

    # Validate that the user has actually filled in the TODO values
    if "YOUR_ACCOUNT_LOCATOR" in SNOWFLAKE_MCP_ENDPOINT:
        raise ValueError(
            "\n"
            "┌─ Configuration Error ──────────────────────────────────────────┐\n"
            "│ SNOWFLAKE_MCP_ENDPOINT has not been set.                       │\n"
            "│ Edit retailiq_agent.py and replace the placeholder, or         │\n"
            "│ run this script on the workshop EC2 instance where credentials │\n"
            "│ are loaded automatically from AWS Secrets Manager.             │\n"
            "└────────────────────────────────────────────────────────────────┘"
        )
    if "YOUR_PAT_TOKEN_HERE" in SNOWFLAKE_PAT_TOKEN:
        raise ValueError(
            "\n"
            "┌─ Configuration Error ──────────────────────────────────────────┐\n"
            "│ SNOWFLAKE_PAT_TOKEN has not been set.                          │\n"
            "│ Generate a PAT in Snowflake and paste it into this file, or    │\n"
            "│ run this script on the workshop EC2 instance.                  │\n"
            "└────────────────────────────────────────────────────────────────┘"
        )

    return SNOWFLAKE_MCP_ENDPOINT, SNOWFLAKE_PAT_TOKEN


# ──────────────────────────────────────────────────────────────────────────────
# System Prompt
# ──────────────────────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """\
You are RetailIQ Assistant, an expert retail analytics AI for RetailIQ, an Italian retail company.

You have access to three MCP tools exposed by the Snowflake Managed MCP Server:

  • retailiq_analyst
    Use for QUANTITATIVE questions: sales, revenue, orders, customers, products, and stores.
    This tool invokes Snowflake Cortex Analyst, which generates and executes SQL against the
    structured RetailIQ data warehouse. Always use it for numbers, trends, and rankings.

  • retailiq_reviews_search
    Use for QUALITATIVE insights from customer reviews — sentiment, product feedback, store
    experiences, and what customers say in their own words.
    This tool invokes Snowflake Cortex Search over the reviews corpus.

  • retailiq_tickets_search
    Use for support and operational insights — delivery issues, returns, complaints, and
    recurring problems surfaced through the customer service ticket corpus.
    This tool invokes Snowflake Cortex Search over the support tickets corpus.

────────────────────────────────────────────────────────────────────────────────
Reasoning guidelines
────────────────────────────────────────────────────────────────────────────────
1. Analytical questions (revenue, trends, rankings, KPIs):
   → Always call retailiq_analyst first to get precise numbers from the data warehouse.

2. Qualitative questions ("what do customers say/think/feel"):
   → Call retailiq_reviews_search and/or retailiq_tickets_search, depending on whether the
     question is about product sentiment or operational issues.

3. Complex, combined questions:
   → Use retailiq_analyst for the quantitative part, then enrich with qualitative context
     from the search tools. Present a unified answer that connects the two perspectives.

4. Attribution: always cite which tool provided which piece of information.
   Example: "According to Cortex Analyst (sales data)... and customers say (reviews)..."

5. Formatting:
   - Currency in EUR with thousands separators (e.g., €1.234.567)
   - Percentages with one decimal place (e.g., 12.4%)
   - Dates as "Month YYYY" (e.g., "March 2025") or ISO for ranges
   - Present tables for comparisons with ≥ 3 items
   - Use bullet points for qualitative findings

6. Geographic specificity: Italy has distinct retail regions (Nord, Centro, Sud e Isole).
   When a question mentions a region, city, or store, always filter appropriately.

7. Time scoping: when a question has no explicit time scope, default to the most recent
   complete quarter. If the question says "year-to-date", use the current calendar year.

8. Uncertainty: if a tool returns no results or an error, say so explicitly and suggest
   an alternative phrasing the user can try. Never fabricate numbers.
"""


# ──────────────────────────────────────────────────────────────────────────────
# MCP Client + Agent construction
# ──────────────────────────────────────────────────────────────────────────────

def build_agent(mcp_endpoint: str, pat_token: str) -> Agent:
    """
    Construct a Strands Agent connected to the Snowflake Managed MCP Server.

    The MCP client is configured with Bearer token auth using the Snowflake PAT.
    All MCP tools exposed by the server (Cortex Analyst + Cortex Search) are
    automatically discovered and made available to the agent.
    """
    # Snowflake Managed MCP Server uses Bearer token authentication
    auth_headers = {
        "Authorization": f"Bearer {pat_token}",
    }

    # Create transport callable for Streamable HTTP with auth headers
    transport_callable = _create_transport_callable(
        "streamable_http",
        server_url=mcp_endpoint,
        headers=auth_headers,
    )

    # MCPClient connects to the server and discovers available tools
    snowflake_mcp = MCPClient(transport_callable)

    # Strands Agent — model ID string auto-resolves to Bedrock using instance role
    agent = Agent(
        model=BEDROCK_MODEL_ID,
        system_prompt=SYSTEM_PROMPT,
        tools=[snowflake_mcp],
    )

    return agent


# ──────────────────────────────────────────────────────────────────────────────
# Sample questions shown on 'help'
# ──────────────────────────────────────────────────────────────────────────────

HELP_TEXT = """
┌─ Sample Questions ─────────────────────────────────────────────────────────┐
│                                                                             │
│  Analytical Questions (uses Cortex Analyst / structured SQL)                │
│  ──────────────────────────────────────────────────────────                 │
│  → What are the top 5 product categories by revenue this quarter?           │
│  → How does revenue compare across Italian regions year-to-date?            │
│  → What is the return rate by product category?                             │
│  → Show the monthly revenue trend for the last 12 months                   │
│  → Which loyalty tier customers generate the most revenue?                  │
│  → How many unique customers made a purchase in Q1 vs Q2?                  │
│                                                                             │
│  Customer Intelligence (uses Cortex Search / semantic retrieval)            │
│  ────────────────────────────────────────────────────────────               │
│  → What are customers saying about electronics products?                    │
│  → Find negative reviews mentioning delivery problems                       │
│  → What are the most common support ticket categories?                      │
│  → Which regions have the most customer complaints?                         │
│  → Show me positive reviews for kitchen appliances                          │
│                                                                             │
│  Combined Analysis (analyst + search together)                              │
│  ─────────────────────────────────────────────                              │
│  → Which product categories have high return rates AND negative reviews?    │
│  → Compare revenue performance with customer satisfaction across regions    │
│  → Identify products that sell well but have quality complaints             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
"""

WELCOME_BANNER = """
╔══════════════════════════════════════════════════════════════╗
║          RetailIQ AI Assistant - Workshop Demo               ║
║    Powered by AWS Bedrock AgentCore + Snowflake Cortex       ║
╚══════════════════════════════════════════════════════════════╝

Ask me anything about RetailIQ's sales, customers, and feedback.
Type 'help' for sample questions, 'quit' to exit.
"""


# ──────────────────────────────────────────────────────────────────────────────
# Tool-call interceptor — prints a brief indicator when the agent calls a tool
# ──────────────────────────────────────────────────────────────────────────────

class ToolCallPrinter:
    """Callback that prints a one-line notice whenever a tool is invoked."""

    _TOOL_LABELS: dict[str, str] = {
        "retailiq_analyst":          "Cortex Analyst  (SQL query)",
        "retailiq_reviews_search":   "Cortex Search   (reviews corpus)",
        "retailiq_tickets_search":   "Cortex Search   (tickets corpus)",
    }

    def __call__(self, **event: Any) -> None:
        tool_name = event.get("tool_name") or event.get("name", "")
        if tool_name:
            label = self._TOOL_LABELS.get(tool_name, tool_name)
            print(f"  [tool] Calling {label}...", flush=True)


# ──────────────────────────────────────────────────────────────────────────────
# Interactive session
# ──────────────────────────────────────────────────────────────────────────────

def run_interactive_session(agent: Agent) -> None:
    """Start the interactive chat loop with multi-turn conversation history."""
    print(WELCOME_BANNER)

    conversation_history: list[dict[str, str]] = []
    tool_printer = ToolCallPrinter()

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\nSession ended. Goodbye!")
            break

        if not user_input:
            continue

        if user_input.lower() in {"quit", "exit", "q", "bye"}:
            print("Goodbye! Hope you enjoyed the RetailIQ workshop.")
            break

        if user_input.lower() in {"help", "?", "examples"}:
            print(HELP_TEXT)
            continue

        if user_input.lower() in {"clear", "reset"}:
            conversation_history.clear()
            print("  [info] Conversation history cleared.\n")
            continue

        # Build the messages list for multi-turn context
        messages = conversation_history + [{"role": "user", "content": user_input}]

        print("")  # blank line before agent response
        print("RetailIQ: ", end="", flush=True)

        try:
            response = agent(
                messages,
                callback_handler=tool_printer,
            )

            # Extract the text content from the response
            reply = _extract_text(response)
            print(reply)
            print("")

            # Append to history for next turn
            conversation_history.append({"role": "user",    "content": user_input})
            conversation_history.append({"role": "assistant", "content": reply})

            # Keep history bounded to last 20 turns (40 messages) to avoid token overflow
            if len(conversation_history) > 40:
                conversation_history = conversation_history[-40:]

        except KeyboardInterrupt:
            print("\n  [info] Response interrupted. Type 'quit' to exit.\n")
            continue
        except ConnectionError as exc:
            print(
                f"\n  [error] Could not reach the Snowflake MCP Server: {exc}\n"
                "  Check that your MCP endpoint URL is correct and that "
                "your instance has outbound HTTPS access.\n"
            )
        except Exception as exc:  # noqa: BLE001
            logger.exception("Unexpected error during agent invocation")
            print(
                f"\n  [error] Unexpected error: {exc}\n"
                "  See logs/agent.log for the full traceback.\n"
            )


def _extract_text(response: Any) -> str:
    """
    Pull the text content out of whatever the Strands Agent returns.
    Strands may return a string, a dict, or a structured response object.
    """
    if isinstance(response, str):
        return response
    if isinstance(response, dict):
        # Strands typically returns {"content": [...], "role": "assistant"}
        content = response.get("content", response.get("text", ""))
        if isinstance(content, list):
            parts = [
                block.get("text", "") if isinstance(block, dict) else str(block)
                for block in content
            ]
            return "".join(parts).strip()
        return str(content).strip()
    # Fallback: convert to string
    return str(response).strip()


# ──────────────────────────────────────────────────────────────────────────────
# AgentCore Runtime — deployment notes
# ──────────────────────────────────────────────────────────────────────────────
#
# To deploy this agent to AWS Bedrock AgentCore Runtime (managed hosting),
# you would:
#
# 1. Package the agent using the AgentCore Starter Toolkit:
#      agentcore init --name retailiq-agent
#      agentcore package --entry-point retailiq_agent.py
#
# 2. Push to AgentCore:
#      agentcore deploy --agent-name retailiq-agent \
#                       --runtime-role <IAM_ROLE_ARN> \
#                       --region us-east-1
#
# 3. Invoke via the AgentCore REST API:
#      aws bedrock-agentcore invoke-agent \
#          --agent-id <AGENT_ID>           \
#          --input-text "What are the top products?"
#
# For the full walkthrough, see the AgentCore documentation:
#   https://docs.aws.amazon.com/bedrock/latest/userguide/agentcore.html
#
# In the runtime environment, credentials are passed as environment variables
# or via an IAM execution role — remove the hardcoded TODO values above and
# rely exclusively on resolve_credentials() / Secrets Manager.
#
# ──────────────────────────────────────────────────────────────────────────────


# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────

def main() -> None:
    # Create logs directory if it does not exist
    log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
    os.makedirs(log_dir, exist_ok=True)

    # Resolve credentials (Secrets Manager on EC2, or hardcoded values locally)
    try:
        mcp_endpoint, pat_token = resolve_credentials()
    except ValueError as exc:
        print(exc, file=sys.stderr)
        sys.exit(1)

    # Build the Strands agent with Snowflake MCP tools
    print("Connecting to Snowflake MCP Server...", end=" ", flush=True)
    try:
        agent = build_agent(mcp_endpoint, pat_token)
        print("OK")
    except Exception as exc:
        print(f"FAILED\n\n[error] Could not initialise the agent: {exc}")
        logger.exception("Agent initialisation failed")
        sys.exit(1)

    # Start the interactive loop
    run_interactive_session(agent)


if __name__ == "__main__":
    main()
