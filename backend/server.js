
const http = require("http");
const { GoogleGenAI } = require("@google/genai");
const OpenAI = require("openai");
const Anthropic = require("@anthropic-ai/sdk");
const PORT = process.env.PORT || 3000;

const apiKey = process.env.GEMINI_API_KEY;

const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;

const anthropic = process.env.ANTHROPIC_API_KEY
  ? new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })
  : null;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.5-flash-lite";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-6.2-astra";
const ANTHROPIC_MODEL = process.env.ANTHROPIC_MODEL || "claude-sonnet-5";

async function generateOpenAIReply(history, message) {
  const response = await openai.responses.create({
    model: OPENAI_MODEL,
    input: [
      ...history.map(item => ({
        role: item.role === "model" ? "assistant" : "user",
        content: item.parts[0].text
      })),
      { role: "user", content: message }
    ]
  });

  return response.output_text || "JARVIS could not generate a reply.";
}

async function generateClaudeReply(history, message) {
  const response = await anthropic.messages.create({
    model: ANTHROPIC_MODEL,
    max_tokens: 1024,
    messages: [
      ...history.map(item => ({
        role: item.role === "model" ? "assistant" : "user",
        content: item.parts[0].text
      })),
      { role: "user", content: message }
    ]
  });

  return response.content
    .filter(item => item.type === "text")
    .map(item => item.text)
    .join("\n") || "JARVIS could not generate a reply.";
}

const server = http.createServer(async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Content-Type", "application/json");

  if (req.method === "OPTIONS") {
    res.writeHead(204);
    return res.end();
  }

  if (req.method === "GET") {
    res.writeHead(200);
    return res.end(JSON.stringify({
      message: "JARVIS Backend Online"
    }));
  }

  if (req.method === "POST" && req.url === "/chat") {
    try {
      let body = "";

      req.on("data", chunk => {
        body += chunk;
        if (body.length > 100000) {
          req.destroy();
        }
      });

      await new Promise((resolve, reject) => {
        req.on("end", resolve);
        req.on("error", reject);
      });

      const data = JSON.parse(body);
      const message = data.message;

      if (typeof message !== "string" || !message.trim()) {
        res.writeHead(400);
        return res.end(JSON.stringify({
          error: "Message is required."
        }));
      }

      const provider = data.provider || "Auto Mode";

      if (!["Auto Mode", "Gemini", "ChatGPT", "Claude"].includes(provider)) {
        res.writeHead(400);
        return res.end(JSON.stringify({
          error: "Invalid AI provider."
        }));
      }

      const history = Array.isArray(data.history)
        ? data.history.slice(-12)
            .filter(item =>
              item &&
              typeof item.text === "string" &&
              item.text.trim() &&
              (item.role === "user" || item.role === "model")
            )
            .map(item => ({
              role: item.role,
              parts: [{ text: item.text.slice(0, 4000) }]
            }))
        : [];

      const contents = [
        ...history,
        {
          role: "user",
          parts: [{ text: message }]
        }
      ];

      // Provider dispatch started
      let reply;

      if (provider === "ChatGPT") {
        if (!openai) {
          res.writeHead(503);
          return res.end(JSON.stringify({
            error: "OpenAI API key is not configured."
          }));
        }
        reply = await generateOpenAIReply(history, message);

      } else if (provider === "Claude") {
        if (!anthropic) {
          res.writeHead(503);
          return res.end(JSON.stringify({
            error: "Anthropic API key is not configured."
          }));
        }
        reply = await generateClaudeReply(history, message);

      } else {
        if (!ai) {
          res.writeHead(503);
          return res.end(JSON.stringify({
            error: "Gemini API key is not configured."
          }));
        }

        let response;
        let lastError;

        for (let attempt = 1; attempt <= 3; attempt++) {
          try {
            response = await ai.models.generateContent({
              model: GEMINI_MODEL,
              contents: contents
            });
            break;
          } catch (error) {
            lastError = error;
            const isTemporaryError =
              error.status === 503 ||
              error.status === 429 ||
              error.status >= 500;

            if (!isTemporaryError || attempt === 3) {
              throw error;
            }

            console.log(`Gemini retry attempt ${attempt + 1}...`);
            await new Promise(resolve =>
              setTimeout(resolve, attempt * 2000)
            );
          }
        }

        if (!response) throw lastError;
        reply = response.text || "JARVIS could not generate a reply.";
      }



      res.writeHead(200);
      return res.end(JSON.stringify({
        reply: reply
      }));

    } catch (error) {
      console.error("AI provider error:", error.message);
      res.writeHead(500);
      return res.end(JSON.stringify({
        error: "JARVIS AI could not process the request."
      }));
    }
  }

  res.writeHead(404);
  res.end(JSON.stringify({ error: "Not found" }));
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`JARVIS running on port ${PORT}`);
});

