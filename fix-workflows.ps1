# Fix Workflow Files Script
# This script directly writes the correct JSON content to the workflow files

Write-Host "=== Fixing Workflow JSON Files ===" -ForegroundColor Blue

# Workflow 1 - Main Automation JSON Content
$workflow1Content = @'
{
  "name": "YouTube Comment Automation - Main",
  "nodes": [
    {
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "cronExpression",
              "expression": "0 */2 * * *"
            }
          ]
        }
      },
      "id": "cron-trigger",
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.cron",
      "typeVersion": 1,
      "position": [240, 300]
    },
    {
      "parameters": {
        "operation": "select",
        "table": "videos",
        "where": {
          "conditions": [
            {
              "column": "posted",
              "operator": "equal",
              "value": false
            },
            {
              "column": "flagged",
              "operator": "equal",
              "value": false
            }
          ]
        },
        "limit": 5
      },
      "id": "supabase-get-videos",
      "name": "Get Unposted Videos",
      "type": "n8n-nodes-base.supabase",
      "typeVersion": 1,
      "position": [460, 300]
    },
    {
      "parameters": {
        "batchSize": 1,
        "options": {}
      },
      "id": "split-videos",
      "name": "Split Videos",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "position": [680, 300]
    },
    {
      "parameters": {
        "operation": "select",
        "table": "youtube_accounts",
        "where": {
          "conditions": [
            {
              "column": "active",
              "operator": "equal",
              "value": true
            }
          ]
        },
        "limit": 30
      },
      "id": "get-accounts",
      "name": "Get YouTube Accounts",
      "type": "n8n-nodes-base.supabase",
      "typeVersion": 1,
      "position": [900, 300]
    },
    {
      "parameters": {
        "batchSize": 1,
        "options": {}
      },
      "id": "split-accounts",
      "name": "Split Accounts",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 3,
      "position": [1120, 300]
    },
    {
      "parameters": {
        "jsCode": "// Generate psychological persuasion thread\nconst videoTitle = $('Split Videos').item.json.title;\nconst videoId = $('Split Videos').item.json.video_id;\nconst account = $('Split Accounts').item.json;\nconst traderUsername = $node[\"Get Settings\"].json.trader_username || \"BullishWhalesClub\";\nconst telegramHandle = $node[\"Get Settings\"].json.telegram_handle || \"@BullishwhalesChief\";\n\n// AI prompt for contextual comment generation\nconst aiPrompt = `\nGenerate a realistic YouTube comment thread for this video: \"${videoTitle}\"\n\nCreate a psychological persuasion sequence following this exact pattern:\n\n1. Frustrated Investor Comment (User A):\n- Express frustration about trading/investing failures\n- Mention specific struggles related to the video topic\n- Sound genuine and desperate for help\n- Mirror the video's theme and language\n- Example: \"Been stuck in REITs all year and it feels like watching paint dry...\"\n\n2. Mysterious Helper Reply (Johnny):\n- Calm, detached response\n- Mention finding something different at ${traderUsername}\n- Talk about live sessions and one-on-one guidance\n- NO CRYPTO mentioned yet\n- Build intrigue without seeming like an ad\n\n3. Meme/Comic Relief (User B):\n- Humorous analogy related to trading/investing\n- Feels like a real person dropping by\n- Tone should match the video's audience\n- Normalizes the pain mentioned in comment 1\n\n4. Crypto Curiosity (User C):\n- Skeptical but curious\n- Ask: \"Is this crypto related?\"\n- First time ${traderUsername} is mentioned by name\n- Make it seem like they've heard of it before\n\n5. Telegram Drop (Johnny):\n- Drop the Telegram handle cleanly: \"${telegramHandle}\"\n- Casual, like he doesn't care\n- Confirm it's crypto-based\n- No hard CTA, just information\n\n6. Scarcity Layer (User D):\n- Mock how no one shares working strategies\n- Add realism: \"Once something works, everybody shuts up\"\n- Create FOMO and exclusivity\n\n7. Comic Relief 2 (User E):\n- Random trading joke\n- Keep thread feeling natural\n- Example: \"Bro just buy whatever Cramer cries about and short it 😂💀\"\n\n8. Curiosity Climbs (User A returns):\n- Confused but hopeful\n- Ask about the trading model\n- Echo reader's internal voice\n\n9. Reveal Model (Johnny):\n- Explain real-time trading\n- \"He takes the trades, breaks it down, you enter with him\"\n- Feels raw and unscripted\n\n10. Skeptic Check (User F):\n- Ask about the catch\n- Give Johnny credibility shot\n\n11. Loop Closed (Johnny):\n- Explain payment model\n- \"You don't pay upfront. You make money, then he makes money\"\n- Skin in the game concept\n\n12. Wisdom Close (User B):\n- Drop advice before leaving\n- \"Patience + conviction + volume = real gains\"\n- End with signal\n\nRULES:\n- Crypto NEVER mentioned before comment 4\n- Telegram handle ONLY in comment 5\n- Thread must feel human and flawed\n- Comments must match video tone\n- Use realistic usernames and grammar errors\n- Add emotional authenticity\n\nGenerate ONLY the comment text for step ${account.comment_step || 1} of this sequence.\nMake it feel genuine and contextual to the video title.\n`;\n\nreturn {\n  videoId,\n  videoTitle,\n  account,\n  aiPrompt,\n  traderUsername,\n  telegramHandle,\n  commentStep: account.comment_step || 1\n};"
      },
      "id": "generate-prompt",
      "name": "Generate AI Prompt",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [1340, 300]
    },
    {
      "parameters": {
        "operation": "select",
        "table": "settings",
        "returnAll": true
      },
      "id": "get-settings",
      "name": "Get Settings",
      "type": "n8n-nodes-base.supabase",
      "typeVersion": 1,
      "position": [900, 140]
    },
    {
      "parameters": {
        "resource": "chat",
        "operation": "create",
        "model": "gpt-4o-mini",
        "messages": {
          "values": [
            {
              "role": "user",
              "content": "={{ $json.aiPrompt }}"
            }
          ]
        },
        "options": {
          "temperature": 0.9,
          "maxTokens": 150
        }
      },
      "id": "openai-generate",
      "name": "OpenAI Generate Comment",
      "type": "n8n-nodes-base.openAi",
      "typeVersion": 1,
      "position": [1560, 300]
    }
  ],
  "connections": {},
  "pinData": {},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": [],
  "triggerCount": 0,
  "updatedAt": "2025-01-01T00:00:00.000Z",
  "versionId": "1"
}
'@

# Workflow 4 - Enhanced AI JSON Content
$workflow4Content = @'
{
  "name": "Enhanced AI-Powered YouTube Automation",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "trigger-post",
        "responseMode": "responseNode",
        "options": {}
      },
      "id": "webhook-trigger",
      "name": "Manual Trigger Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "position": [240, 300],
      "webhookId": "manual-post-trigger"
    },
    {
      "parameters": {
        "jsCode": "// Extract video ID from webhook payload\nconst body = $json.body || {};\nconst videoId = body.video_id || $json.video_id;\n\nif (!videoId) {\n  throw new Error('No video_id provided in request');\n}\n\nreturn { video_id: videoId };"
      },
      "id": "extract-video-id",
      "name": "Extract Video ID",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [460, 300]
    },
    {
      "parameters": {
        "operation": "select",
        "table": "videos",
        "where": {
          "conditions": [
            {
              "column": "video_id",
              "operator": "equal",
              "value": "={{ $json.video_id }}"
            }
          ]
        }
      },
      "id": "get-video-info",
      "name": "Get Video Info",
      "type": "n8n-nodes-base.supabase",
      "typeVersion": 1,
      "position": [680, 300]
    },
    {
      "parameters": {
        "resource": "chat",
        "operation": "create",
        "model": "gpt-4o-mini",
        "messages": {
          "values": [
            {
              "role": "system",
              "content": "You are an expert at creating authentic YouTube comments that blend naturally into finance and trading discussions."
            },
            {
              "role": "user",
              "content": "Generate a frustrated investor comment for this video"
            }
          ]
        },
        "options": {
          "temperature": 0.9,
          "maxTokens": 200
        }
      },
      "id": "openai-enhanced",
      "name": "OpenAI Enhanced",
      "type": "n8n-nodes-base.openAi",
      "typeVersion": 1,
      "position": [900, 300]
    }
  ],
  "connections": {},
  "pinData": {},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": [],
  "triggerCount": 0,
  "updatedAt": "2025-01-01T00:00:00.000Z",
  "versionId": "1"
}
'@

# Write the content to files
try {
    Write-Host "Writing Workflow 1 content..." -ForegroundColor Cyan
    $workflow1Content | Out-File -FilePath "n8n-workflows/workflow_1_main_automation.json" -Encoding UTF8 -Force
    Write-Host "✅ Workflow 1 updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Workflow 1: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    Write-Host "Writing Workflow 4 content..." -ForegroundColor Cyan
    $workflow4Content | Out-File -FilePath "n8n-workflows/workflow_4_enhanced_ai.json" -Encoding UTF8 -Force
    Write-Host "✅ Workflow 4 updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to update Workflow 4: $($_.Exception.Message)" -ForegroundColor Red
}

# Check file sizes
Write-Host "`nChecking file sizes..." -ForegroundColor Cyan
Get-ChildItem "n8n-workflows/*.json" | Select-Object Name, Length | Format-Table

Write-Host "`nWorkflow files have been updated!" -ForegroundColor Green
Write-Host "Run .\test.ps1 to verify the changes." -ForegroundColor Yellow