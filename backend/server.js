
const http = require("http");
const { GoogleGenAI } = require("@google/genai");

const PORT = process.env.PORT || 3000;

const apiKey = process.env.GEMINI_API_KEY;

const ai = apiKey ? new GoogleGenAI({ apiKey }) : null;

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
      if (!ai) {
        res.writeHead(500);
        return res.end(JSON.stringify({
          error: "Gemini API key is not configured."
        }));
      }

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

      if (provider !== "Auto Mode" && provider !== "Gemini") {
        res.writeHead(400);
        return res.end(JSON.stringify({
          error: "This AI provider is not configured yet."
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

      let response;
let lastError;

for (let attempt = 1; attempt <= 3; attempt++) {
  try {
    response = await ai.models.generateContent({
      model: "gemini-3.5-flash-lite",
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

if (!response) {
  throw lastError;
}

      res.writeHead(200);
      return res.end(JSON.stringify({
        reply: response.text || "JARVIS could not generate a reply."
      }));

    } catch (error) {
      console.error("Gemini error:", error.message);
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

