# Enterprise AI Agents: Snowflake Cortex × AWS Bedrock AgentCore
## Hands-On Workshop — AWS Tech Summit 2026

**Duration:** 2 hours | **Audience:** AWS Solution Architects | **Format:** Pair labs

---

## What You'll Build

By the end of this workshop, you will have deployed a production-style AI agent that:

1. Answers **quantitative business questions** ("What is revenue by region this quarter?") by generating and executing SQL against a Snowflake **Semantic View** via **Cortex Analyst**
2. Answers **qualitative questions** ("What are customers saying about delivery?") via **Cortex Search** over unstructured review and ticket data
3. Orchestrates both capabilities through the **Snowflake Managed MCP Server**, exposed to **AWS Bedrock AgentCore** as a fully managed, multi-turn conversational agent

```
┌─────────────────────────────────────────────────────┐
│              AWS Bedrock AgentCore                  │
│   ┌──────────────────┐  ┌─────────────────────────┐ │
│   │  Strands Agent   │  │  AgentCore Memory       │ │
│   │  (Claude 3.5)    │◄─│  (multi-turn context)   │ │
│   └────────┬─────────┘  └─────────────────────────┘ │
└────────────┼────────────────────────────────────────┘
             │  MCP over HTTPS + PAT Auth
┌────────────▼────────────────────────────────────────┐
│         Snowflake Managed MCP Server                │
│  ┌─────────────────┐  ┌────────────────────────┐    │
│  │  Cortex Analyst │  │  Cortex Search         │    │
│  │  (Semantic View)│  │  (reviews + tickets)   │    │
│  └─────────────────┘  └────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

---

## Scenario: RetailIQ

RetailIQ is an Italian multi-channel retailer with 50 stores across Italy plus an online shop. The data covers:
- **50,000 orders** across 3 years (2022–2024)
- **5,000 customers** with loyalty tiers and regional data
- **200 products** across 5 categories
- **50 stores** across Italian regions
- **15,000 customer reviews** (for Cortex Search)
- **8,000 support tickets** (for Cortex Search)

---

## Prerequisites

**Snowflake:**
- A Snowflake account with Cortex features enabled (Cortex Search, Cortex Analyst, MCP Server)
- ACCOUNTADMIN access (or an admin who can run `01_setup_environment.sql`)

**AWS:**
- AWS account with access to Amazon Bedrock
- A Claude Sonnet model subscribed in AWS Marketplace
- IAM permissions to deploy CloudFormation stacks and create Secrets Manager secrets

**Local (facilitator only):**
- Python 3.9+ with pandas, numpy, faker (`pip install pandas numpy faker`)
- To generate the dataset: `python 00_data/generate_data.py`

---

## Workshop Modules

| Module | Topic | Time | File |
|--------|-------|------|------|
| 0 | Architecture overview & setup | 15 min | `01_snowflake_setup/01_setup_environment.sql` |
| 1 | Load data & explore the schema | 10 min | `01_snowflake_setup/02_create_tables.sql` + `03_load_data.sql` |
| 2 | Build & tune a Semantic View | 25 min | `02_semantic_view/retailiq_semantic_view.yaml` |
| 3 | Cortex Search services | 10 min | `01_snowflake_setup/04_create_search_service.sql` |
| 4 | Cortex Agent (native, in CoWork) | 15 min | `01_snowflake_setup/05_create_mcp_server.sql` |
| 5 | MCP Server + PAT Token | 10 min | `01_snowflake_setup/05_create_mcp_server.sql` |
| 6 | AWS Bedrock AgentCore setup | 15 min | `03_aws_setup/agentcore_cfn.yaml` |
| 7 | Strands agent — end-to-end | 10 min | `03_aws_setup/retailiq_agent.py` |
| 8 | Multi-turn demo + production patterns | 10 min | — |

---

## Step-by-Step Instructions

### Module 0 — Environment Setup `[15 min]`

> Run as **ACCOUNTADMIN**

Open `01_snowflake_setup/01_setup_environment.sql` in a Snowflake SQL worksheet and run it top to bottom.

This creates:
- Role `RETAILIQ_ROLE` and user `retailiq_user`
- Warehouse `RETAILIQ_WH` (XSmall, auto-suspend 60s)
- Database `RETAILIQ_DB` and schema `ANALYTICS`
- Stage `RETAILIQ_STG` for data loading

> **Presenter tip:** While this runs, explain the Snowflake object hierarchy to the audience.

---

### Module 1 — Load Data `[10 min]`

**Step 1:** Upload the CSV files to the Snowflake stage.

In Snowsight: `Catalog → Data → RETAILIQ_DB → ANALYTICS → Stages → RETAILIQ_STG`
Click `+ Files` and upload:
- `00_data/orders.csv`
- `00_data/products.csv`
- `00_data/customers.csv`
- `00_data/stores.csv`
- `00_data/customer_reviews.csv`
- `00_data/support_tickets.csv`

**Step 2:** Run `01_snowflake_setup/02_create_tables.sql` to create tables.

**Step 3:** Run `01_snowflake_setup/03_load_data.sql` to load data.

Expected row counts after loading:
```
orders:           ~50,000
products:            ~200
customers:         ~5,000
stores:               ~50
customer_reviews: ~15,000
support_tickets:   ~8,000
```

> **Discussion point:** Ask participants to query the raw data and try to answer "What is revenue by region this year?" manually. They'll write 15+ lines of SQL. This motivates the Semantic View.

---

### Module 2 — Semantic View: Build & Tune `[25 min]`

> The most important module. Take your time here.

#### What is a Semantic View?

A Semantic View is a **business vocabulary layer** that sits between your raw tables and Cortex Analyst. It defines:
- How tables **join** to each other
- What **dimensions** and **metrics** mean in business terms
- **Synonyms** so the AI understands "revenue", "fatturato", "sales" all mean the same thing
- **Verified Queries** — pre-validated SQL for your most important KPIs

**The key insight for SA architects:** *A Semantic View gives you full control over the vocabulary and logic the AI uses. The difference between a bare auto-generated SV and a tuned one with verified queries is the difference between a demo and a production deployment.*

#### Step 2a — Auto-Generated (Minimal) Semantic View (5 min)

Cortex Analyst always requires a Semantic View — there's no "zero SV" mode. But the quality of the SV determines the quality of the answers. Let's start with a bare-bones auto-generated one to see the gap.

1. Navigate to `AI & ML → Cortex Analyst → Create New`
2. Select **Generate from tables** (not "Upload YAML")
3. Pick all 4 tables: `ORDERS`, `PRODUCTS`, `CUSTOMERS`, `STORES`
4. Let the UI auto-generate joins and columns — accept defaults and save as `RETAILIQ_SV_BASIC`

Now ask:
> "What is the revenue by region for this year?"

Observe: the auto-generated SV has no concept of "revenue" (it doesn't know to filter `status='Completed'`), "region" is ambiguous (customer region? store region?), and there are no synonyms. The generated SQL is likely wrong or imprecise.

#### Step 2b — Upload the Tuned Semantic View (10 min)

Now let's replace it with the hand-crafted SV that has metrics, synonyms, and verified queries.

1. Navigate to `AI & ML → Cortex Analyst → Create New`
2. Select `Upload your YAML file`
3. Upload `02_semantic_view/retailiq_semantic_view.yaml`
4. Select `RETAILIQ_DB → ANALYTICS` then `RETAILIQ_STG` stage
5. Click `Upload` then `Save`

> While it processes, walk through the YAML structure: tables, relationships, dimensions, metrics, verified_queries. Highlight what the auto-generated SV was missing.

#### Step 2c — Test with the Tuned Semantic View (5 min)

Ask the same question again with `RETAILIQ_SV` (the tuned one). Compare:
- The SQL now correctly uses `SUM(total_amount) WHERE status='Completed'`
- "Region" resolves unambiguously to `customers.region`
- Synonyms mean "fatturato", "revenue", "sales" all work

#### Step 2d — Tune Further: Add a Verified Query (5 min)

In the Analyst UI, click on the Semantic View and add a new Verified Query:
- Question: "What is our return rate by product category?"
- Use the SQL from `retailiq_semantic_view.yaml` as a reference
- Save and re-test — the VQ guarantees the exact SQL you validated

**Takeaway:** Verified Queries are the single most impactful tuning mechanism. They guarantee correct SQL for your most important business questions. Start with auto-generate to get a baseline, then iteratively add metrics, synonyms, and VQs.

---

### Module 3 — Cortex Search `[10 min]`

Run `01_snowflake_setup/04_create_search_service.sql`.

This creates two search services:
- `RETAILIQ_REVIEWS_SEARCH` — over customer review text
- `RETAILIQ_TICKETS_SEARCH` — over support ticket text

**Test queries to demonstrate semantic matching (not just keyword):**

```
"delivery problems in southern Italy"
→ finds reviews mentioning slow shipping, lost packages, Sicilia/Napoli

"customers unhappy with electronics"
→ finds negative reviews about tech products without needing exact keywords

"refund not processed"
→ finds support tickets about billing and returns
```

**Key message for SA architects:** Cortex Search is a **hybrid search** (full-text + vector embedding) with no infrastructure to manage. Zero vector database to deploy, zero embedding pipeline to maintain.

---

### Module 4 — Cortex Agent in CoWork `[15 min]`

Run `01_snowflake_setup/05_create_mcp_server.sql` — the `CREATE CORTEX AGENT` section.

This creates a native Snowflake agent that orchestrates both Analyst and Search.

**Open CoWork:** `AI & ML → CoWork → New Session` and select `RETAILIQ_CORTEX_AGENT`.

**Demo questions (run in this order to show progressive complexity):**

1. `"What are our top 5 categories by revenue this quarter?"`
   → Analyst only, clean structured answer

2. `"What do customers say about our electronics products?"`
   → Search only, qualitative insights

3. `"Which product categories have the highest return rates, and what are customers saying about those returns?"`
   → **Both tools** — the agent reasons: first Analyst for return rates, then Search for context

4. `"Compare revenue performance by region — and are there regions with more complaints?"`
   → Cross-tool reasoning, visible in the CoWork reasoning trace

> **Live demo moment:** Show the reasoning trace (tool selection, tool calls, synthesis). This is the "aha moment" for most SA architects.

---

### Module 5 — Snowflake Managed MCP Server `[10 min]`

Run the MCP Server creation section of `01_snowflake_setup/05_create_mcp_server.sql`.

```sql
DESCRIBE MCP SERVER RETAILIQ_MCP_SERVER;
-- Copy the endpoint URL from the result — you'll need it for AWS
```

Also run the PAT Token creation from `01_snowflake_setup/01_setup_environment.sql` (the section at the bottom).

```sql
-- Save this token — it's shown only once!
ALTER USER retailiq_user ADD PROGRAMMATIC ACCESS TOKEN retailiq_mcp_token 
  DAYS_TO_EXPIRY = 7 
  ROLE_RESTRICTION = 'RETAILIQ_ROLE';
```

**What to save before the next module:**
```
MCP Endpoint URL:  https://YOUR_LOCATOR.snowflakecomputing.com/mcp/...
PAT Token:         <token value shown once>
Account Locator:   YOUR_LOCATOR (bottom-left in Snowsight → Account Details)
```

**Key message:** The MCP endpoint is a standards-based interface. Any MCP client — Bedrock AgentCore, Claude Desktop, VS Code, your own app — can connect without any custom Snowflake SDK.

---

### Module 6 — AWS Bedrock AgentCore Setup `[15 min]`

**Deploy the CloudFormation stack:**

1. Go to AWS Console → CloudFormation → Create Stack
2. Upload `03_aws_setup/agentcore_cfn.yaml`
3. Fill in parameters:
   - `SnowflakeMCPEndpoint`: the URL from Module 5
   - `SnowflakePATToken`: the PAT token from Module 5
   - `SnowflakeAccountLocator`: your account locator
   - `KeyPairName`: an existing EC2 key pair
   - `SubnetId` / `VpcId`: a public subnet in any VPC
4. Acknowledge IAM creation and click Submit

**Wait ~5 minutes** for the stack to complete.

5. Go to Outputs → `Ec2ConnectionURL` → click to open AWS CloudShell or use EC2 Instance Connect

```bash
cd /opt/retailiq
ls -la  # verify files are present
python3 --version  # should be 3.11+
```

---

### Module 7 — Strands Agent End-to-End `[10 min]`

On the EC2 instance:

```bash
# The credentials are already injected from Secrets Manager
# Just run the agent
python3 retailiq_agent.py
```

You'll see the welcome banner. Test with the sample questions from `help`:

```
> What are the top 5 product categories by revenue this quarter?
> What are customers saying about electronics?
> Which regions have the most delivery complaints, and how does their revenue compare?
```

**Watch the terminal output** — you'll see:
- Which tool was selected (Analyst vs Search)
- The query sent to each tool
- How the agent synthesizes the answer

**Multi-turn demo** (shows AgentCore Memory value):

```
> Analyze revenue by region for this year
[Agent returns regional breakdown]

> Focus on the bottom 3 regions — what are customers saying there?
[Agent remembers the regions from turn 1, searches reviews for those regions]

> What actions would you recommend for those regions?
[Agent synthesizes both data streams into recommendations]
```

---

### Module 8 — Production Patterns & Q&A `[10 min]`

**Production Architecture Decisions:**

| Decision | Development | Production |
|----------|------------|------------|
| Auth | PAT token, 7 days | PAT + Network Policy + IP allowlist |
| Role | RETAILIQ_ROLE | Least-privilege read-only role |
| Warehouse | XSmall | Auto-scaling cluster |
| MCP scope | All tools | Tool-level RBAC per team |
| Monitoring | Console logs | AgentCore traces + Snowflake QUERY_HISTORY |

**Security pattern — lock down MCP to AgentCore IPs only:**

```sql
-- After getting AgentCore NAT Gateway IPs from AWS:
CREATE OR REPLACE NETWORK POLICY agentcore_only
  ALLOWED_IP_LIST = ('X.X.X.X/32', 'Y.Y.Y.Y/32')  -- AgentCore NAT IPs
  COMMENT = 'Restrict MCP access to AgentCore egress IPs only';

ALTER USER retailiq_user SET NETWORK_POLICY = agentcore_only;
```

**Seed Q&A questions (for facilitators):**
- *"Can I use this with Bedrock Knowledge Bases instead of Cortex Search?"* → Yes, but you lose Snowflake governance and the hybrid search quality
- *"What's the latency like?"* → Typical: Analyst ~2-5s, Search ~1-2s, full agent turn ~5-12s
- *"Does AgentCore support streaming?"* → Yes, the Strands SDK supports streaming responses
- *"Can multiple teams share the same MCP server?"* → Yes, tool-level access is controlled by role grants
- *"Is there a cost calculator?"* → Show Cortex token pricing + AgentCore runtime pricing

---

## Cleanup

Run `01_snowflake_setup/06_cleanup.sql` to remove all Snowflake objects.

In AWS: delete the CloudFormation stack (`agentcore-retailiq-workshop`).

---

## Resources

- [Snowflake Cortex Agents docs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- [Snowflake Managed MCP Server](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-mcp)
- [Cortex Analyst & Semantic Views](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)
- [Amazon Bedrock AgentCore](https://aws.amazon.com/bedrock/agentcore/)
- [Strands Agents SDK](https://strandsagents.com)
- [AWS + Snowflake Reference Architecture](https://catalog.us-east-1.prod.workshops.aws/workshops/2d4e5ea4-78c8-496f-8246-50d8971414c9)
