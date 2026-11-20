export default {
  async fetch(request) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: corsHeaders()
      });
    }

    if (request.method !== "POST") {
      return Response.json(
        { message: "JARVIS Backend Online" },
        { headers: corsHeaders() }
      );
    }

    return Response.json(
      { reply: "JARVIS Backend is ready." },
      { headers: corsHeaders() }
    );
  }
};

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json"
  };
}
